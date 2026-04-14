import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedAllData() async {
    debugPrint('🌱 Starting Firestore seeding...');
    
    await seedPlans();
    await seedExperts();
    await seedExplore();
    await seedFAQ();
    await seedDefaultTrends();
    
    debugPrint('✅ Firestore seeding complete!');
  }

  static Future<void> seedPlans() async {
    final plans = [
      {
        'id': 'basic',
        'name': 'Basic',
        'icon_name': 'auto_awesome',
        'price_monthly': 0,
        'price_yearly': 0,
        'period': 'Forever',
        'description': 'Perfect for getting started with Intellix',
        'is_popular': false,
        'features': [
          'AI Assistant (Limited)',
          '5 Expert Sessions/month',
          'Basic Analytics',
          'Community Access',
          'Mobile App Access',
          'Email Support'
        ],
        'gradient_from': '#9CA3AF',
        'gradient_to': '#6B7280',
        'sort_order': 1,
      },
      {
        'id': 'pro',
        'name': 'Pro',
        'icon_name': 'flash_on',
        'price_monthly': 29,
        'price_yearly': 278,
        'period': 'per month',
        'description': 'For professionals who need more power',
        'is_popular': true,
        'features': [
          'Unlimited AI Assistant',
          '20 Expert Sessions/month',
          'Advanced Analytics',
          'Priority Support',
          'Custom Reports',
          'Team Collaboration (up to 5)',
          'API Access',
          'Data Export'
        ],
        'gradient_from': '#5B9FF3',
        'gradient_to': '#7DB6F7',
        'sort_order': 2,
      },
      {
        'id': 'enterprise',
        'name': 'Enterprise',
        'icon_name': 'workspace_premium',
        'price_monthly': 99,
        'price_yearly': 950,
        'period': 'per month',
        'description': 'For teams and organizations',
        'is_popular': false,
        'features': [
          'Everything in Pro',
          'Unlimited Expert Sessions',
          'Custom AI Training',
          'Dedicated Account Manager',
          'Advanced Security',
          'Unlimited Team Members',
          'Custom Integrations',
          'SLA Guarantee',
          'White-label Options',
          'On-premise Deployment'
        ],
        'gradient_from': '#0284C7',
        'gradient_to': '#06B6D4',
        'sort_order': 3,
      },
    ];

    for (var plan in plans) {
      await _firestore.collection('plans').doc(plan['id'] as String).set(plan);
    }
  }

  static Future<void> seedExperts() async {
    final experts = [
      {
        'id': '1',
        'name': 'Asst. Prof. Ghassan A. QasMarrogy',
        'email': 'ghassan.qasmarrogy@cihanuniversity.edu.iq',
        'title': 'Assistant Professor – Computer Science',
        'specialty': 'Artificial Intelligence & Machine Learning',
        'rating': 4.9,
        'reviews': 143,
        'hourly_rate': 0,
        'image': 'assets/experts/ghassan_qasmarrogy.jpg',
        'availability': 'Sun, Mon, Wed',
        'years_experience': 14,
        'sessions_completed': 210,
        'bio':
            'Asst. Prof. Ghassan A. QasMarrogy is a distinguished researcher and educator at Cihan University with over 14 years of experience in Artificial Intelligence and Machine Learning. He has led numerous research projects in natural language processing, computer vision, and intelligent systems, and has supervised graduate students whose work has been published in international journals.',
        'schedule': [
          {'day': 'Sunday',    'slots': ['09:00', '10:00', '14:00', '15:00']},
          {'day': 'Monday',    'slots': ['09:00', '10:00', '14:00', '15:00']},
          {'day': 'Wednesday', 'slots': ['11:00', '12:00', '15:00', '16:00']},
        ],
      },
      {
        'id': '2',
        'name': 'Duaa Haider Mustafa',
        'email': 'duaa.mustafa@cihanuniversity.edu.iq',
        'title': 'Lecturer – Software Engineering',
        'specialty': 'Software Development & Project Management',
        'rating': 4.8,
        'reviews': 97,
        'hourly_rate': 0,
        'image': 'assets/experts/duaa_mustafa.jpg',
        'availability': 'Mon, Tue, Thu',
        'years_experience': 9,
        'sessions_completed': 175,
        'bio':
            'Duaa Haider Mustafa is an experienced software engineering lecturer specializing in agile methodologies, software architecture, and full-stack development. She actively mentors students in real-world project delivery and has collaborated with local tech startups to bridge the gap between academia and industry.',
        'schedule': [
          {'day': 'Monday',   'slots': ['10:00', '11:00', '15:00', '16:00']},
          {'day': 'Tuesday',  'slots': ['10:00', '11:00', '15:00', '16:00']},
          {'day': 'Thursday', 'slots': ['09:00', '10:00', '13:00', '14:00']},
        ],
      },
      {
        'id': '3',
        'name': 'Firas Muhammad Zeki',
        'email': 'firas.zeki@cihanuniversity.edu.iq',
        'title': 'Lecturer – Data Science',
        'specialty': 'Data Analytics & Business Intelligence',
        'rating': 4.85,
        'reviews': 112,
        'hourly_rate': 0,
        'image': 'assets/experts/firas_zeki.jpg',
        'availability': 'Sun, Wed, Thu',
        'years_experience': 11,
        'sessions_completed': 198,
        'bio':
            'Firas Muhammad Zeki brings over 11 years of expertise in data science and business intelligence. He has worked with regional enterprises to implement data-driven decision systems and teaches advanced analytics, statistical modelling, and visualization tools at Cihan University. His sessions are highly practical and tailored to real business problems.',
        'schedule': [
          {'day': 'Sunday',    'slots': ['08:00', '09:00', '13:00', '14:00']},
          {'day': 'Wednesday', 'slots': ['08:00', '09:00', '13:00', '14:00']},
          {'day': 'Thursday',  'slots': ['10:00', '11:00', '14:00', '15:00']},
        ],
      },
      {
        'id': '4',
        'name': 'Adil Al-Dalowi',
        'email': 'adil.mohammed@cihanuniversity.edu.iq',
        'title': 'Lecturer – Computer Networks',
        'specialty': 'Networking, Cybersecurity & Cloud Infrastructure',
        'rating': 4.75,
        'reviews': 88,
        'hourly_rate': 0,
        'image': 'assets/experts/adil_aldalowi.jpg',
        'availability': 'Mon, Tue, Sat',
        'years_experience': 13,
        'sessions_completed': 165,
        'bio':
            'Adil Al-Dalowi is a networking and cybersecurity specialist with 13 years of combined academic and industry experience. He holds certifications in Cisco technologies and cloud platforms, and assists organizations in designing secure, scalable network infrastructures. His consulting sessions focus on practical threat mitigation and infrastructure optimization.',
        'schedule': [
          {'day': 'Monday',   'slots': ['11:00', '12:00', '16:00', '17:00']},
          {'day': 'Tuesday',  'slots': ['11:00', '12:00', '16:00', '17:00']},
          {'day': 'Saturday', 'slots': ['09:00', '10:00', '12:00', '13:00']},
        ],
      },
      {
        'id': '5',
        'name': 'Dr. Hasan Fahmi Al-Delawi',
        'email': 'hasan.hassan@cihanuniversity.edu.iq',
        'title': 'Doctor – Information Systems',
        'specialty': 'Enterprise Systems & Digital Transformation',
        'rating': 4.92,
        'reviews': 159,
        'hourly_rate': 0,
        'image': 'assets/experts/hasan_aldelawi.jpg',
        'availability': 'Sun, Tue, Wed',
        'years_experience': 18,
        'sessions_completed': 340,
        'bio':
            'Dr. Hasan Fahmi Al-Delawi holds a doctorate in Information Systems and has been a cornerstone of digital strategy consulting in the Kurdistan region for nearly two decades. He specialises in ERP design, digital transformation roadmaps, and enterprise architecture. His research is widely cited, and he is frequently invited as a keynote speaker at regional technology conferences.',
        'schedule': [
          {'day': 'Sunday',    'slots': ['09:00', '10:00', '14:00', '15:00']},
          {'day': 'Tuesday',   'slots': ['09:00', '10:00', '14:00', '15:00']},
          {'day': 'Wednesday', 'slots': ['10:00', '11:00', '15:00', '16:00']},
        ],
      },
      {
        'id': '6',
        'name': 'Mardin Anwer',
        'email': 'mardin.anwer@cihanuniversity.edu.iq',
        'title': 'Lecturer – Human–Computer Interaction',
        'specialty': 'UX/UI Design & Product Development',
        'rating': 4.88,
        'reviews': 102,
        'hourly_rate': 0,
        'image': 'assets/experts/mardin_anwer.jpg',
        'availability': 'Mon, Thu, Sat',
        'years_experience': 8,
        'sessions_completed': 187,
        'bio':
            'Mardin Anwer is a passionate UX/UI designer and HCI researcher who blends academic rigour with hands-on design practice. With 8 years of experience, she has designed digital products for education, healthcare, and e-commerce sectors across the region. She coaches teams on user research methodologies, prototyping, and accessibility-first design principles.',
        'schedule': [
          {'day': 'Monday',   'slots': ['10:00', '11:00', '15:00', '16:00']},
          {'day': 'Thursday', 'slots': ['10:00', '11:00', '15:00', '16:00']},
          {'day': 'Saturday', 'slots': ['11:00', '12:00', '14:00', '15:00']},
        ],
      },
      {
        'id': '7',
        'name': 'Yazen Mahmood',
        'email': 'yazen.mahmood@cihanuniversity.edu.iq',
        'title': 'Lecturer – Mobile & Web Development',
        'specialty': 'Full-Stack & Mobile Application Development',
        'rating': 4.82,
        'reviews': 115,
        'hourly_rate': 0,
        'image': 'assets/experts/yazen_mahmood.jpg',
        'availability': 'Sun, Mon, Fri',
        'years_experience': 10,
        'sessions_completed': 223,
        'bio':
            'Yazen Mahmood is a full-stack and mobile developer with 10 years of experience building scalable web and mobile applications. He teaches Flutter, React, and Node.js at Cihan University and actively mentors students in their capstone projects. He has delivered freelance and contract solutions for organisations across Iraq and the wider MENA region.',
        'schedule': [
          {'day': 'Sunday', 'slots': ['08:00', '09:00', '13:00', '14:00']},
          {'day': 'Monday', 'slots': ['08:00', '09:00', '13:00', '14:00']},
          {'day': 'Friday', 'slots': ['10:00', '11:00', '14:00', '15:00']},
        ],
      },
      {
        'id': '8',
        'name': 'Liza Suliman Jawdat',
        'email': 'liza.jawdat@cihanuniversity.edu.iq',
        'title': 'Lecturer – Database Systems',
        'specialty': 'Database Design, SQL & NoSQL Systems',
        'rating': 4.78,
        'reviews': 91,
        'hourly_rate': 0,
        'image': 'assets/experts/liza_jawdat.jpg',
        'availability': 'Tue, Wed, Fri',
        'years_experience': 10,
        'sessions_completed': 192,
        'bio':
            'Liza Suliman Jawdat is an expert in relational and non-relational database architecture with a decade of experience in both academia and enterprise consulting. She teaches advanced SQL, MongoDB, and cloud-based database solutions at Cihan University. Her consulting work helps businesses design efficient, secure, and highly available data storage solutions.',
        'schedule': [
          {'day': 'Tuesday',   'slots': ['11:00', '12:00', '16:00', '17:00']},
          {'day': 'Wednesday', 'slots': ['11:00', '12:00', '16:00', '17:00']},
          {'day': 'Friday',    'slots': ['09:00', '10:00', '13:00', '14:00']},
        ],
      },
    ];

    for (var expert in experts) {
      await _firestore.collection('experts').doc(expert['id'] as String).set(expert);
    }
  }


  static Future<void> seedExplore() async {
    final categories = [
      {'id': 'business', 'name': 'Business', 'icon_name': 'business_center', 'gradient_from': '#3B82F6', 'gradient_to': '#2563EB', 'post_count': 142},
      {'id': 'analytics', 'name': 'Analytics', 'icon_name': 'bar_chart', 'gradient_from': '#06B6D4', 'gradient_to': '#0891B2', 'post_count': 98},
      {'id': 'marketing', 'name': 'Marketing', 'icon_name': 'campaign', 'gradient_from': '#EC4899', 'gradient_to': '#DB2777', 'post_count': 76},
      {'id': 'technology', 'name': 'Technology', 'icon_name': 'code', 'gradient_from': '#10B981', 'gradient_to': '#059669', 'post_count': 124},
    ];

    for (var cat in categories) {
      await _firestore.collection('explore_categories').doc(cat['id'] as String).set(cat);
    }

    final articles = [
      {
        'id': 1,
        'title': '10 Data-Driven Strategies to Scale Your Business in 2025',
        'category': 'Business Strategy',
        'read_time': '8 min read',
        'views': '12.5K',
        'is_featured': true,
        'image_url': 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800&q=80',
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'id': 2,
        'title': 'Effective Marketing Strategies for Digital Transformation',
        'category': 'Marketing',
        'read_time': '5 min read',
        'views': '6.7K',
        'is_featured': false,
        'image_url': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&q=80',
        'created_at': FieldValue.serverTimestamp(),
      },
    ];

    for (var art in articles) {
      await _firestore.collection('articles').doc(art['id'].toString()).set(art);
    }
  }

  static Future<void> seedFAQ() async {
    final faqs = [
      {
        'category': 'Getting Started',
        'questions': [
          {'q': 'How do I create an account?', 'a': 'Tap on "Sign Up" from the login screen and fill in your details.'},
          {'q': 'What is Intellix?', 'a': 'Intellix is an AI-powered business intelligence platform.'},
        ]
      },
      {
        'category': 'Support',
        'questions': [
          {'q': 'How do I contact support?', 'a': 'Go to Settings > Support > Contact Support.'},
        ]
      }
    ];

    for (var faq in faqs) {
      await _firestore.collection('faq').add(faq);
    }
  }

  static Future<void> seedDefaultTrends() async {
    final trends = {
      'metrics': [
        {'name': 'Revenue', 'value': '\$47.2K', 'change': 12.5, 'positive': true},
        {'name': 'Active Users', 'value': '2,847', 'change': 8.3, 'positive': true},
      ],
      'revenue': [
        {'label': 'Jan', 'amount': 4200},
        {'label': 'Feb', 'amount': 3800},
        {'label': 'Mar', 'amount': 5100},
      ],
      'categories': [
        {'name': 'Electronics', 'percentage': 35, 'color': '#0284C7'},
        {'name': 'Fashion', 'percentage': 28, 'color': '#0EA5E9'},
      ]
    };

    await _firestore.collection('default_data').doc('trends').set(trends);
  }
}
