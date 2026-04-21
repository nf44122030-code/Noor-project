import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'vertex_ai_service.dart';
import '../../features/expert/data/models/expert.dart';
import '../../features/notification/data/models/notification_model.dart';
import '../../features/ai/data/models/message.dart';
import '../utils/market_data_seeder.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- Market Insights ---
  Future<List<Map<String, dynamic>>> getMarketInsights() async {
    try {
      final snapshot =
          await _firestore.collection('iraq_market_insights').get();
      final docs = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      
      if (docs.isEmpty) {
        debugPrint('⚠️ Fetch returned 0 items. Supplying fallback local definitions.');
        return MarketDataSeeder.generateInsights();
      }
      return docs;
    } catch (e) {
      debugPrint('Error fetching market insights (likely unauthenticated): $e. Using local data fallback.');
      return MarketDataSeeder.generateInsights();
    }
  }

  // --- Assistant / Delegate Logic ---
  String? _cachedEffectiveUid;

  /// Returns the effective UID for the current session.
  /// If the current user is an assistant, this returns their master's UID.
  /// Otherwise, it returns their own UID.
  Future<String?> getEffectiveUid() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    if (_cachedEffectiveUid != null) {
      return _cachedEffectiveUid;
    }

    try {
      if (user.email != null) {
        final assistantDoc =
            await _firestore.collection('assistants').doc(user.email).get();
        if (assistantDoc.exists) {
          final data = assistantDoc.data();
          if (data != null && data['master_uid'] != null) {
            _cachedEffectiveUid = data['master_uid'] as String;
            return _cachedEffectiveUid;
          }
        }
      }
    } catch (e) {
      debugPrint('Error retrieving effective UID: $e');
    }

    _cachedEffectiveUid = user.uid;
    return _cachedEffectiveUid;
  }

  /// Clears the cached UID (e.g., on sign out)
  void clearEffectiveUidCache() {
    _cachedEffectiveUid = null;
  }

  // --- Assistants Management ---
  Future<void> addAssistant(String email) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be logged in to add an assistant');

    // We register the assistant using their email as the Document ID.
    // So when they log in, they can immediately inherit the master's UID.
    await _firestore.collection('assistants').doc(email).set({
      'master_uid': user.uid,
      'master_email': user.email,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeAssistant(String email) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Must be logged in to remove an assistant');
    }

    // Make sure we only remove if it belongs to this master (security)
    final doc = await _firestore.collection('assistants').doc(email).get();
    if (doc.exists && doc.data()?['master_uid'] == user.uid) {
      await _firestore.collection('assistants').doc(email).delete();
    }
  }

  Stream<List<Map<String, dynamic>>> getAssistantsStream() async* {
    final user = _auth.currentUser;
    if (user == null) yield* const Stream.empty();

    final effectiveUid = await getEffectiveUid();
    yield* _firestore
        .collection('assistants')
        .where('master_uid', isEqualTo: effectiveUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'email': doc.id, ...doc.data()})
            .toList());
  }

  // --- Experts ---
  Future<List<Expert>> getExperts() async {
    try {
      debugPrint('🔍 [FIREBASE] Attempting to fetch experts...');

      final snapshot = await _firestore.collection('experts').get(const GetOptions(source: Source.serverAndCache));
      debugPrint(
          '🔍 [FIREBASE] Snapshot received. Document count: ${snapshot.docs.length}');

      final List<Expert> experts = [];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          debugPrint(
              '🔍 [FIREBASE] Parsing expert: ${doc.id} | Data: ${data.keys.take(5).toList()}...');
          experts.add(Expert.fromJson({...data, 'id': doc.id}));
        } catch (e) {
          debugPrint('❌ [FIREBASE] Failed to parse expert ${doc.id}: $e');
        }
      }
      debugPrint(
          '✅ [FIREBASE] Total experts successfully parsed: ${experts.length}');
      return experts;
    } catch (e) {
      debugPrint('❌ [FIREBASE] Critical error in getExperts: $e');
      return [];
    }
  }

  /// Returns a real-time stream of all experts, updating instantly when any expert profile changes.
  Stream<List<Expert>> getExpertsStream() {
    return _firestore.collection('experts').snapshots().map((snapshot) {
      final List<Expert> experts = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final expert = Expert.fromJson({...data, 'id': doc.id});
          debugPrint('📡 [STREAM] Expert "${expert.name}" (docId: ${doc.id}) has ${expert.schedule.length} schedule days: ${expert.schedule.map((s) => '${s.day}(${s.slots.length})').join(', ')}');
          experts.add(expert);
        } catch (e) {
          debugPrint('❌ [FIREBASE] Failed to parse expert ${doc.id}: $e');
        }
      }
      return experts;
    });
  }

  // --- Booking Lifecycle ---

  /// Creates a new booking document with status = 'pending'.
  Future<String?> bookSession({
    required String expertId,
    required String expertName,
    required String expertEmail,
    required String sessionDate, // e.g. "Sunday, Apr 6, 2026"
    required String sessionTime, // e.g. "09:00"
    required String duration,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Build an ISO string for reminder comparison
    String? isoDate;
    try {
      final parts = sessionTime.split(':');
      final parsed = DateTime(
        DateTime.now().year,
        1,
        1,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      // Approximate: store date string + time offset (full parse done at reminder check)
      isoDate = '${sessionDate}_${parsed.hour}:${parsed.minute}';
    } catch (_) {}

    final doc = await _firestore.collection('bookings').add({
      'user_id': await getEffectiveUid(),
      'user_name': user.displayName ?? '',
      'user_email': user.email ?? '',
      'expert_id': expertId,
      'expert_name': expertName,
      'expert_email': expertEmail,
      'session_date': sessionDate,
      'session_time': sessionTime,
      'session_date_raw': isoDate ?? sessionDate,
      'duration': duration,
      'notes': notes ?? '',
      'status': 'pending', // pending | confirmed | completed | cancelled
      'reminder_sent': false,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Send notification to the expert
    try {
      await _firestore.collection('notifications').add({
        'user_id': expertId,
        'title': 'New Booking Request',
        'description': '${user.displayName ?? 'A user'} has requested a session on $sessionDate at $sessionTime.',
        'type': 'session',
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
        'icon_name': 'event',
      });
    } catch (e) {
      debugPrint("Error sending booking notification to expert: $e");
    }

    return doc.id;
  }

  /// Returns all bookings for the current user, newest first.
  Future<List<Map<String, dynamic>>> getMyBookings() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    
    // Sort locally to avoid Firestore composite index requirement on (user_id, created_at)
    final snap = await _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: await getEffectiveUid())
        .get();
        
    final docs = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    docs.sort((a, b) {
      final aTime = (a['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bTime = (b['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    return docs;
  }

  /// Returns a real-time stream of bookings for the current user.
  Stream<List<Map<String, dynamic>>> getMyBookingsStream() async* {
    final uid = await getEffectiveUid();
    
    yield* _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
          docs.sort((a, b) {
            final aTime = (a['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime = (b['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });
          return docs;
        });
  }

  /// Marks booking as confirmed and returns the generated 5-digit session code.
  Future<String> confirmBooking(String bookingId) async {
    final code = (10000 + Random().nextInt(90000)).toString();
    
    // Get booking to find user_id
    final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
    final bookingData = bookingDoc.data();

    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'confirmed',
      'session_code': code,
      'confirmed_at': FieldValue.serverTimestamp(),
    });

    // Send notification to the user
    if (bookingData != null && bookingData['user_id'] != null) {
      try {
        await _firestore.collection('notifications').add({
          'user_id': bookingData['user_id'],
          'title': 'Booking Confirmed',
          'description': 'Your session with ${bookingData['expert_name'] ?? 'an expert'} has been confirmed. Session Code: $code',
          'type': 'session',
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
          'icon_name': 'check_circle',
        });
      } catch (e) {
        debugPrint("Error sending approval notification to user: $e");
      }
    }

    return code;
  }

  /// Marks booking as rejected by the expert.
  Future<void> rejectBooking(String bookingId, {String? reason}) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'rejected',
      'reject_reason': reason ?? '',
      'rejected_at': FieldValue.serverTimestamp(),
    });
  }

  /// Marks booking as cancelled and triggers email #5 to both parties.
  Future<void> cancelBooking(String bookingId,
      {String cancelledBy = 'user', String? reason}) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'cancelled',
      'cancelled_by': cancelledBy,
      'cancel_reason': reason ?? '',
      'cancelled_at': FieldValue.serverTimestamp(),
    });
  }

  /// Permanently deletes a booking record from the database.
  Future<void> deleteBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).delete();
  }

  // ── Video Call Signaling ────────────────────────────────────────────────────────

  /// Updates the booking to alert the expert that the user is waiting/ringing.
  Future<void> initiateCall(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'call_status': 'ringing',
    });
  }

  /// Updates the booking to show the call is active.
  Future<void> answerCall(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'call_status': 'in_progress',
    });
  }

  // ────────────────────────────────────────────────────────────────────────────────

  /// Marks booking as completed and triggers email #4 to the user.
  Future<void> completeBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'completed',
      'completed_at': FieldValue.serverTimestamp(),
    });
  }

  // --- Expert Portal Mode Methods ---

  /// Returns all bookings for a specific expert in real-time.
  Stream<List<Map<String, dynamic>>> getExpertBookingsStream(String expertEmail) {
    return _firestore
        .collection('bookings')
        .where('expert_email', isEqualTo: expertEmail)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
          // Sort client-side (newest first) to avoid requiring a composite Firestore index
          docs.sort((a, b) {
            final aTs = a['created_at'];
            final bTs = b['created_at'];
            if (aTs == null || bTs == null) return 0;
            return bTs.compareTo(aTs);
          });
          return docs;
        });
  }

  /// Updates an expert's profile data (e.g. schedule, bio).
  /// Uses merge-set to avoid read-before-write issues with offline cache.
  Future<void> updateExpertProfileData(
      String expertId, Map<String, dynamic> data) async {
    debugPrint('🔄 [FIREBASE] updateExpertProfileData — docId: "$expertId", keys: ${data.keys.toList()}');
    final docRef = _firestore.collection('experts').doc(expertId);
    await docRef.set(data, SetOptions(merge: true));
    // Force a server read-back to confirm the write was persisted
    final verify = await docRef.get(const GetOptions(source: Source.server));
    debugPrint('✅ [FIREBASE] Verified write — doc exists: ${verify.exists}, schedule length: ${(verify.data()?['schedule'] as List?)?.length ?? 'null'}');
  }

  // --- Notifications ---
  Stream<List<NotificationModel>> getNotificationsStream() async* {
    final user = _auth.currentUser;
    if (user == null) yield* Stream.value([]);

    final effectiveUid = await getEffectiveUid();
    yield* _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: effectiveUid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                NotificationModel.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  Future<void> markNotificationAsRead(String id) async {
    await _firestore
        .collection('notifications')
        .doc(id)
        .update({'is_read': true});
  }

  Future<void> markAllNotificationsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snap = await _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: await getEffectiveUid())
        .where('is_read', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }

  Future<void> clearAllNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snap = await _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: await getEffectiveUid())
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- Explore ---
  Future<List<Map<String, dynamic>>> getExploreCategories() async {
    final snapshot = await _firestore.collection('explore_categories').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<Map<String, dynamic>> getArticles() async {
    final snapshot = await _firestore.collection('articles').get();
    final docs = snapshot.docs.map((doc) => doc.data()).toList();
    return {
      'featured': docs.firstWhere((a) => a['is_featured'] == true,
          orElse: () => docs.first),
      'recent': docs.where((a) => a['is_featured'] != true).toList(),
    };
  }

  /// AI-Powered dynamic articles that update based on real-world trends
  Future<Map<String, dynamic>> getDynamicArticles(
      {bool forceRefresh = false}) async {
    try {
      final docRef =
          _firestore.collection('default_data').doc('daily_insights');
      final doc = await docRef.get();

      // Ultra-Fast Cache: Refresh every 2 mins to ensure high-frequency variety
      bool shouldRefresh = true;
      if (doc.exists && !forceRefresh) {
        final lastUpdate = (doc.data()?['last_update'] as Timestamp?)?.toDate();
        if (lastUpdate != null) {
          final difference = DateTime.now().difference(lastUpdate).inMinutes;
          if (difference < 2) {
            shouldRefresh = false;
            debugPrint(
                'Content is fresh ($difference mins old). Serving from cache.');
          }
        }
      }
      if (shouldRefresh) {
        final now = DateTime.now();

        // Randomized focus topics to ensure variety
        final focusTopics = [
          'Emerging Markets & VC trends',
          'Generative AI in Enterprise',
          'SaaS Productivity & Workflow',
          'Green Tech & Sustainability',
          'E-commerce & Consumer behavior',
          'FinTech & Blockchain evolution',
          'Crypto & Web3 developments',
          'Silicon Valley & Startup news'
        ];
        final randomFocus = focusTopics[now.second % focusTopics.length];

        final prompt = '''
          You are a high-end business news editor. 
          Use your Google Search tool to find the LATEST real-world business and tech news from the last 24 hours related to "$randomFocus".
          
          Generate a JSON array of 6 UNIQUE, fresh insights. 
          Each insight must be a real person, company, or event currently in the news.
          
          Include a mix of: [Finance, Tech, AI, Strategy, Market]. 
          Format: [{"title": "Headline", "category": "Category", "summary": "2-sentence breakdown", "id": "unique-slug", "read_time": "3 min read", "views": "1.2k views"}]
          
          Return ONLY the JSON array.
        ''';

        debugPrint(
            'Asking Vertex AI for GROUNDED insights with focus: $randomFocus...');
        final response = await VertexAiService.generateGroundedInsights(prompt);
        if (response != null) {
          // Robust JSON extraction from AI response
          String cleanJson = response.trim();
          final firstBracket = cleanJson.indexOf('[');
          final lastBracket = cleanJson.lastIndexOf(']');

          if (firstBracket != -1 &&
              lastBracket != -1 &&
              lastBracket > firstBracket) {
            cleanJson = cleanJson.substring(firstBracket, lastBracket + 1);
          }

          try {
            final List<dynamic> parsed =
                List.from(cleanJson.isEmpty ? [] : (jsonDecode(cleanJson)));

            if (parsed.isNotEmpty) {
              debugPrint('Parsed ${parsed.length} dynamic articles from AI.');
              // Add images and map to Article structure
              final curated = parsed.map((item) {
                final category = item['category']?.toString() ?? 'Business';
                String imgKeyword = 'office';

                // Broader keyword mapping
                final catLower = category.toLowerCase();
                if (catLower.contains('finance') ||
                    catLower.contains('money') ||
                    catLower.contains('market')) {
                  imgKeyword = 'financial';
                } else if (catLower.contains('tech')) {
                  imgKeyword = 'technology';
                } else if (catLower.contains('ai') ||
                    catLower.contains('robot')) {
                  imgKeyword = 'artificial-intelligence';
                } else if (catLower.contains('strategy') ||
                    catLower.contains('plan')) {
                  imgKeyword = 'strategy-planning';
                } else if (catLower.contains('marketing')) {
                  imgKeyword = 'marketing-branding';
                }

                return {
                  ...item,
                  'image_url':
                      'https://images.unsplash.com/photo-${_getUnsplashId(imgKeyword)}?auto=format&fit=crop&q=80&w=800',
                  'is_featured': parsed.indexOf(item) == 0,
                  'id': item['id'] ?? 'insight-${parsed.indexOf(item)}',
                };
              }).toList();

              try {
                await docRef.set({
                  'articles': curated,
                  'last_update': FieldValue.serverTimestamp(),
                });
              } catch (cacheError) {
                debugPrint(
                    'Could not update global cache (likely permissions), continuing with local data: $cacheError');
              }

              return {
                'featured': curated.first,
                'recent': curated.skip(1).toList(),
              };
            }
          } catch (e) {
            debugPrint('Error parsing/saving dynamic articles: $e');
          }
        }
      }

      // Fallback: If refresh was skipped or failed, serve from Firestore cache
      if (doc.exists) {
        final rawList = doc.data()?['articles'] as List? ?? [];
        final curated = rawList
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        if (curated.isNotEmpty) {
          debugPrint(
              'Serving ${curated.length} articles from Firestore cache.');
          return {
            'featured': curated.first,
            'recent': curated.skip(1).toList(),
          };
        }
      }

      // Fallback 2: Static database articles
      final staticArticles = await getArticles();
      if ((staticArticles['recent'] as List).isNotEmpty) {
        debugPrint('Serving articles from static database fallback.');
        return staticArticles;
      }
    } catch (e) {
      debugPrint('Dynamic insights error: $e');
    }

    // Fallback 3: Hardcoded Expert Safety-Net (Ultimate Fail-safe)
    debugPrint('Serving content from HARDCODED SAFETY-NET.');
    final safetyNet = [
      {
        'title': 'AI Transformation: The Next Decade of Enterprise Strategy',
        'category': 'Strategy',
        'summary':
            'As AI matures from experimental to essential, businesses must pivot their long-term strategies to leverage generative models for actual operational efficiency.',
        'read_time': '5 min read',
        'views': '1.8k views',
        'id': 'safety-01'
      },
      {
        'title': 'Global Market Resilience Amidst Interest Rate Volatility',
        'category': 'Market',
        'summary':
            'Despite the unpredictable shifts in US Treasury yields, emerging markets are showing surprising resilience as diversification reaches new heights in Q2 2026.',
        'read_time': '4 min read',
        'views': '2.1k views',
        'id': 'safety-02'
      },
      {
        'title': 'The Rise of Hyper-Personalised Marketing Engines',
        'category': 'Marketing',
        'summary':
            'Modern brands are no longer using segments—they are using individuals. AI is enabling a 1-to-1 relationship at scale that was previously impossible.',
        'read_time': '3 min read',
        'views': '1.5k views',
        'id': 'safety-03'
      },
      {
        'title': 'FinTech 2.0: Beyond Digital Banking to Smart Equity',
        'category': 'Finance',
        'summary':
            'The next wave of finance isn\'t just about digital access; it is about algorithmically-driven wealth management that levels the playing field for all investors.',
        'read_time': '6 min read',
        'views': '2.4k views',
        'id': 'safety-04'
      }
    ];

    final safetyCurated = safetyNet.asMap().entries.map((entry) {
      final item = entry.value;
      final List<String> safetyImages = [
        'https://loremflickr.com/800/600/finance,stockmarket?lock=100',
        'https://loremflickr.com/800/600/technology,startup?lock=101',
        'https://loremflickr.com/800/600/marketing,business?lock=102',
        'https://loremflickr.com/800/600/artificialintelligence,robotics?lock=103',
      ];
      return {
        ...item,
        'image_url': safetyImages[entry.key],
        'is_featured': entry.key == 0,
      };
    }).toList();

    return {
      'featured': safetyCurated.first,
      'recent': safetyCurated.skip(1).toList(),
    };
  }

  // Helper to get consistent High-Stability Unsplash IDs for categories
  String _getUnsplashId(String keyword) {
    final Map<String, String> ids = {
      'financial': '1551288049-bebda4e38f71', // High-tech Data/Network
      'technology': '1573164713988-8665fc963095', // Elite Tech Professional
      'artificial-intelligence':
          '1516321318423-f06f85e504b3', // Deep AI Network
      'strategy-planning':
          '1531482615713-2afd69097998', // Strategic Business Leaders
      'marketing-branding':
          '1504384545340-562a0ea2af6b', // Modern Work & Growth
      'office': '1522071820081-009f0129c71c', // Premium Team Collaboration
    };
    return ids[keyword] ?? ids['office']!;
  }

  // --- Trends ---
  Future<Map<String, dynamic>> getTrends() async {
    final doc = await _firestore.collection('default_data').doc('trends').get();
    return doc.data() ?? {};
  }

  // --- AI Chat ---
  Future<List<Map<String, dynamic>>> getAiSessions() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final snapshot = await _firestore
        .collection('ai_sessions')
        .where('user_id', isEqualTo: await getEffectiveUid())
        .get();

    final docs =
        snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    docs.sort((a, b) {
      final aTime =
          (a['updated_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final bTime =
          (b['updated_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
    return docs;
  }

  Stream<List<Map<String, dynamic>>> getAiSessionsStream() async* {
    final user = _auth.currentUser;
    if (user == null) yield* Stream.value([]);

    final effectiveUid = await getEffectiveUid();
    yield* _firestore
        .collection('ai_sessions')
        .where('user_id', isEqualTo: effectiveUid)
        .snapshots()
        .map((snap) {
      final docs =
          snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      docs.sort((a, b) {
        final aTime =
            (a['updated_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final bTime =
            (b['updated_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
      return docs;
    });
  }

  Future<void> deleteAiSession(String sessionId) async {
    final messagesSnap = await _firestore
        .collection('ai_sessions')
        .doc(sessionId)
        .collection('messages')
        .get();
    final batch = _firestore.batch();
    for (final doc in messagesSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('ai_sessions').doc(sessionId));
    await batch.commit();
  }

  Stream<List<Message>> getChatMessagesStream({String? sessionId}) {
    final id = (sessionId == null || sessionId.isEmpty) ? 'default' : sessionId;
    return _firestore
        .collection('ai_sessions')
        .doc(id)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  Future<void> sendChatMessage(String text,
      {required String sessionId,
      List<Map<String, dynamic>>? attachments}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (text.trim().isEmpty && (attachments == null || attachments.isEmpty)) {
      return;
    }

    final sessionRef = _firestore.collection('ai_sessions').doc(sessionId);
    final messagesRef = sessionRef.collection('messages');

    // 1. Upsert session metadata
    final sessionDoc = await sessionRef.get();
    bool isNew = !sessionDoc.exists;

    await sessionRef.set({
      'user_id': user.uid,
      'updated_at': FieldValue.serverTimestamp(),
      'last_message': text,
      if (isNew) 'created_at': FieldValue.serverTimestamp(),
      if (isNew) 'title': 'New conversation',
    }, SetOptions(merge: true));

    // 2. Clear empty text if attachments exist, use a placeholder to avoid empty prompt errors
    String promptText = text;
    if (promptText.trim().isEmpty &&
        (attachments != null && attachments.isNotEmpty)) {
      promptText = "(Analyzing attached document(s)...)";
    }

    await messagesRef.add({
      'text': promptText,
      'type': 'user',
      'timestamp': FieldValue.serverTimestamp(),
      'has_attachments': attachments != null && attachments.isNotEmpty,
    });

    // 3. Add typing indicator
    final botMsgRef = await messagesRef.add({
      'text': '...',
      'type': 'bot',
      'timestamp': FieldValue.serverTimestamp(),
    });

    try {
      // 4. Build Context — More reliable to build LOCALLY for the current turn
      final previousHistorySnap = await messagesRef
          .orderBy('timestamp', descending: true)
          .limit(12) // Get enough context
          .get();

      final history = <Map<String, String>>[];

      // A. Add user's bio/booking info as system context first
      final userContext = await _buildUserContext(user.uid);
      if (userContext.isNotEmpty) {
        history.add({'role': 'system', 'content': userContext});
      }

      // B. Build conversation history from Firestore
      // Filter out the typing indicator and the message we JUST sent (we will add it manually)
      final List<Map<String, String>> conversationHistory = [];
      for (var doc in previousHistorySnap.docs.reversed) {
        final data = doc.data();
        final content = data['text'] as String? ?? '';
        final type = data['type'] as String? ?? '';

        // Skip placeholders
        if (content == '...' || doc.id == botMsgRef.id) continue;

        // If it's the message we just sent, skip it here so we can add the "unsynced" local one at the end
        // This avoids double-adding if Firestore is very fast, or missing if Firestore is slow.
        if (content == promptText && type == 'user') continue;

        conversationHistory.add({
          'role': type == 'user' ? 'user' : 'assistant',
          'content': content,
        });
      }

      // C. Add the current conversation pieces to the final request
      history.addAll(conversationHistory);

      // D. Finally add the message we JUST SENT as the very last user turn
      history.add({
        'role': 'user',
        'content': promptText,
      });

      // 5. Call Vertex AI
      final aiResponse = await VertexAiService.getMultimodalCompletion(
        history,
        attachments: attachments,
      );

      // 6. Update bot message
      if (aiResponse != null) {
        await botMsgRef.update({
          'text': aiResponse,
        });
      } else {
        await botMsgRef.update({
          'text':
              'I encountered a silent failure processing this request. This usually happens if the PDF is password-protected or exceeds the memory limit.',
        });
      }

      // 7. Generate title if first message
      if (isNew) {
        _generateSessionTitle(promptText, sessionRef);
      }
    } catch (e) {
      debugPrint('Chat error: $e');
      await botMsgRef.update({
        'text':
            'Multimodal Error: $e. Please verify that Vertex AI for Firebase is configured correctly in your console.'
      });
    }
  }

  Future<String> _buildUserContext(String uid) async {
    try {
      final profileDoc = await _firestore.collection('users').doc(uid).get();
      String name = 'User';
      String bio = '';
      if (profileDoc.exists) {
        final p = profileDoc.data()!;
        name = p['name'] ?? 'User';
        bio = p['bio'] ?? '';
      }

      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('appLanguage') ?? 'en';
      String languageInstruction = 'You must respond in English.';
      if (lang == 'ar') {
        languageInstruction =
            'You MUST reply exclusively in Arabic (العربية) while maintaining the professional business advisor persona.';
      } else if (lang == 'ckb') {
        languageInstruction =
            'You MUST reply exclusively in Kurdish Sorani (کوردی) while maintaining the professional business advisor persona.';
      }

      // ── Fetch Iraq market data for AI context ──
      String marketDataContext = '';
      try {
        final marketSnap = await _firestore.collection('iraq_market_insights').get();
        if (marketSnap.docs.isNotEmpty) {
          final buffer = StringBuffer();
          buffer.writeln('==============================');
          buffer.writeln('IRAQ MARKET INTELLIGENCE DATABASE');
          buffer.writeln('==============================');
          buffer.writeln('Below is REAL market data from the Intellix platform database.');
          buffer.writeln('Use this data to give PRECISE, data-backed answers about Iraqi markets.');
          buffer.writeln('All financial figures are in Iraqi Dinar (IQD).');
          buffer.writeln('');

          // Group by city for readability
          final Map<String, List<Map<String, dynamic>>> byCity = {};
          for (final doc in marketSnap.docs) {
            final d = doc.data();
            final city = d['city'] as String? ?? 'Unknown';
            byCity.putIfAbsent(city, () => []).add(d);
          }

          for (final entry in byCity.entries) {
            buffer.writeln('--- ${entry.key} ---');
            for (final d in entry.value) {
              final area = d['area'] ?? '';
              final industry = d['industry'] ?? '';
              final category = d['category'] ?? '';
              final competition = d['competition_level'] ?? '';
              final success = d['success_probability'] ?? '';
              final risk = d['risk_level'] ?? '';
              final fin = d['financials'] as Map<String, dynamic>? ?? {};
              final startup = fin['avg_startup_cost'] ?? '';
              final opCost = fin['avg_monthly_operational_cost'] ?? '';
              final margin = fin['profitability_margin'] ?? '';
              final revenue = fin['revenue_projections'] as Map<String, dynamic>? ?? {};
              final audience = d['audience'] as Map<String, dynamic>? ?? {};
              final demographics = audience['target_demographics'] ?? [];
              final marketSize = audience['market_size_est'] ?? '';
              final trends = d['trends'] as List<dynamic>? ?? [];
              final geoRec = d['geo_recommendation'] ?? '';

              buffer.writeln('  $area | $industry > $category');
              buffer.writeln('    Competition: $competition/100 | Success Probability: $success% | Risk: $risk');
              buffer.writeln('    Startup Cost: $startup IQD | Monthly OpCost: $opCost IQD | Margin: $margin');
              if (revenue.isNotEmpty) {
                buffer.writeln('    Revenue Projections: ${revenue.entries.map((e) => "${e.key}: ${e.value} IQD").join(", ")}');
              }
              buffer.writeln('    Market Size: $marketSize | Demographics: ${demographics.join(", ")}');
              if (trends.isNotEmpty) {
                buffer.writeln('    Demand Trends: ${trends.map((t) => "${t['year']}: ${t['demand_index']}").join(", ")}');
              }
              buffer.writeln('    Insight: $geoRec');
              buffer.writeln('');
            }
          }

          buffer.writeln('IMPORTANT: When the user asks about any city, area, industry, or category above, you MUST reference this exact data. Do NOT make up numbers. Cite the specific competition level, success probability, startup costs, and trends from this database.');
          marketDataContext = buffer.toString();
        }
      } catch (e) {
        debugPrint('Market data fetch for AI context failed: $e');
      }

      return '''
==============================
IDENTITY
==============================
You are Intellix AI — a smart business intelligence assistant built for entrepreneurs, startups, SMEs, and enterprises. You reason like a data analyst, business consultant, and strategic advisor. You have FULL ACCESS to the Intellix Iraq Market Intelligence Database and must use it to provide precise, data-driven answers.

==============================
DOMAIN RESTRICTION — CRITICAL
==============================
You are an assistant for the Intellix platform ONLY. You must ONLY answer questions related to:
- Business strategy, planning, and management
- Financial planning, forecasting, and analysis
- Market research and competitive analysis
- Entrepreneurship, startups, and SME operations
- The user's own data, sessions, bookings, and account on Intellix
- Features and usage of the Intellix platform
- Iraqi market conditions, area profiles, competition data, and trends

If the user asks ANYTHING outside this domain, you MUST respond with exactly:
"I am Intellix AI, a business intelligence assistant. I can only help with business strategy, market analysis, financial planning, or questions about your Intellix account. Is there a business challenge I can help you with?"

==============================
FORMATTING & TONE — CRITICAL
==============================
1. DO NOT use any markdown characters. Absolutely NO asterisks (*), hashtags (#), or bolding. Write purely in plain, flat text.
2. If the user sends a very short or one-word message (like "Hi" or "high"), do NOT write long essays or overreact. Simply reply with a short, polite 1-2 sentence greeting and ask how you can help. Match the length and tone of the user's input.
3. When citing market data, present numbers naturally in sentences (e.g. "The competition level in Bakhtiari for high-end cafes is 74 out of 100 with a 63% success probability").

==============================
USER CONTEXT
==============================
User Name: $name
User Bio/Details: $bio

==============================
LANGUAGE INSTRUCTION — CRITICAL
==============================
$languageInstruction

$marketDataContext

(Use this context silently to personalize your advice when relevant.)
'''
          .trim();
    } catch (_) {
      return '';
    }
  }

  Future<void> _generateSessionTitle(
      String firstMsg, DocumentReference sessionRef) async {
    try {
      final prompt =
          'Generate a 4-word title for this business conversation: "$firstMsg"';
      final title = await VertexAiService.generateGroundedInsights(prompt);
      if (title != null) {
        await sessionRef.update({'title': title.replaceAll('"', '').trim()});
      }
    } catch (_) {}
  }

  // --- Plans ---
  Future<List<Map<String, dynamic>>> getPricingPlans() async {
    List<Map<String, dynamic>> combinedPlans = [];

    // Always include a virtual "Starter" (Free) plan for comparison
    combinedPlans.add({
      'productId': 'starter_product',
      'id': 'free',
      'name': 'Starter',
      'description': 'Perfect for getting started with basic AI tools.',
      'price': 0,
      'isYearly': false,
      'period': 'forever',
      'icon_name': 'auto_awesome',
      'popular': false,
      'gradientFrom': '#94A3B8',
      'gradientTo': '#64748B',
      'features': ['Full AI access'], // Starter only has the 1st feature
    });

    try {
      final productsSnapshot = await _firestore
          .collection('products')
          .where('active', isEqualTo: true)
          .get();

      for (var productDoc in productsSnapshot.docs) {
        final productData = productDoc.data();
        final pricesSnapshot = await productDoc.reference
            .collection('prices')
            .where('active', isEqualTo: true)
            .get();

        for (var priceDoc in pricesSnapshot.docs) {
          final priceData = priceDoc.data();

          final metadata = productData['metadata'] ?? {};
          final name = productData['name'] ?? '';
          final isPro = name.toLowerCase().contains('pro');
          final isPremium = name.toLowerCase().contains('premium');

          combinedPlans.add({
            'productId': productDoc.id,
            'id': priceDoc.id,
            'name': name,
            'description':
                productData['description'] ?? 'Unlock advanced features.',
            'price': ((priceData['unit_amount'] ?? 0) / 100).round(),
            'period':
                priceData['interval'] == 'year' ? 'per year' : 'per month',
            'isYearly': priceData['interval'] == 'year',
            'icon_name': isPremium
                ? 'workspace_premium'
                : (isPro ? 'flash_on' : 'auto_awesome'),
            'popular': isPro,
            'gradientFrom':
                metadata['gradientFrom'] ?? (isPremium ? '#8B5CF6' : '#2563EB'),
            'gradientTo':
                metadata['gradientTo'] ?? (isPremium ? '#D946EF' : '#0EA5E9'),
            'features': ['Full AI access', 'Business analytics', 'Support'],
          });
        }
      }
    } catch (e) {
      debugPrint('Stripe products fetch error (likely empty/permissions): $e');
    }

    // FALLBACK: If Stripe collection is empty, load the legacy 'plans' collection
    if (combinedPlans.isEmpty) {
      final plansSnapshot = await _firestore.collection('plans').get();
      for (var doc in plansSnapshot.docs) {
        final data = doc.data();
        combinedPlans.add({
          'id': data['id'] ?? doc.id,
          'name': data['name'] ?? 'Plan',
          'description': data['description'] ?? '',
          'price': (data['price_monthly'] ?? data['price'] ?? 0) as int,
          'period': data['period'] ?? 'per month',
          'isYearly': false,
          'icon_name': data['icon_name'] ?? 'auto_awesome',
          'popular': data['is_popular'] ?? false,
          'gradientFrom': data['gradient_from'] ?? '#0284C7',
          'gradientTo': data['gradient_to'] ?? '#0EA5E9',
          'features': (data['features'] is List)
              ? List<String>.from(data['features'])
              : [],
        });
      }
    }

    combinedPlans
        .sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));
    return combinedPlans;
  }

  Future<Map<String, dynamic>> purchaseSubscription(
      String priceId, String planName, bool isYearly) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // 1. Create checkout session doc
      final docRef = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add({
        'price': priceId,
        'success_url':
            'https://intellix-b03b0.web.app/notifications', // Generic fallback
        'cancel_url': 'https://intellix-b03b0.web.app/',
      });

      // 2. Wait for the Stripe Extension to write the `url` to the document
      String? checkoutUrl;
      int attempts = 0;

      while (checkoutUrl == null && attempts < 20) {
        // wait up to ~10 seconds
        await Future.delayed(const Duration(milliseconds: 500));
        final docSnap = await docRef.get();
        final data = docSnap.data();

        if (data != null) {
          if (data.containsKey('url')) {
            checkoutUrl = data['url'];
          } else if (data.containsKey('error')) {
            throw Exception(data['error']['message'] ?? 'Unknown Stripe error');
          }
        }
        attempts++;
      }

      if (checkoutUrl == null) {
        throw Exception(
            'Timeout waiting for checkout URL. Ensure Firebase Stripe Extension is configured.');
      }

      return {
        'success': true,
        'message': 'Checkout ready',
        'checkoutUrl': checkoutUrl,
      };
    } catch (e) {
      debugPrint('Checkout error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // --- FAQ ---
  Future<List<Map<String, dynamic>>> getFaqs() async {
    final snapshot = await _firestore.collection('faq').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
  // --- Analytics History ---
  Future<void> uploadAnalyticsData(Uint8List bytes, String fileName, String ext, int rowCount) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final fileId = DateTime.now().millisecondsSinceEpoch.toString();
    final storageRef = _storage.ref().child('users/${user.uid}/analytics/$fileId.$ext');

    await storageRef.putData(bytes);
    final downloadUrl = await storageRef.getDownloadURL();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('analytics_history')
        .doc(fileId)
        .set({
      'fileId': fileId,
      'name': fileName,
      'ext': ext,
      'rowCount': rowCount,
      'url': downloadUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getAnalyticsHistory() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('analytics_history')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> deleteAnalyticsData(String fileId, String ext) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('analytics_history')
        .doc(fileId)
        .delete();

    try {
      final storageRef = _storage.ref().child('users/${user.uid}/analytics/$fileId.$ext');
      await storageRef.delete();
    } catch (e) {
      debugPrint('Error deleting storage file (it might already be deleted): $e');
    }
  }

  Future<Uint8List?> downloadAnalyticsData(String url) async {
    try {
      final storageRef = _storage.refFromURL(url);
      final bytes = await storageRef.getData(10485760); // 10MB limit
      return bytes;
    } catch (e) {
      debugPrint('Error downloading analytics data: $e');
      return null;
    }
  }
}
