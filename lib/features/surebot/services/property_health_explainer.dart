import '../../../core/phs/phs_categories.dart';
import '../../report/models/property_health_report.dart';

/// Assessment-grounded explanations in the six supported HomeSureAI languages.
/// This is rule-based text, not generative AI. It never recalculates the score.
class PropertyHealthExplainer {
  const PropertyHealthExplainer();

  static const supportedLanguages = {'en', 'kn', 'hi', 'te', 'ta', 'ml'};

  static const Map<String, Map<String, String>> _copy = {
    'en': {
      'low':
          'The assessment indicates substantial areas that need careful investigation. Review the highest-priority findings and obtain supporting evidence before making decisions.',
      'medium':
          'The assessment identifies areas that may need further review. Focus on the listed risks, lower-scoring categories and outstanding evidence.',
      'positive':
          'The assessment is relatively positive, but the score alone does not establish that the property or its documents are fully verified. Review the remaining findings.',
      'high':
          'The assessment score is high. Still verify supporting documents and investigate any listed risks before relying on the result for a property decision.',
      'categoryLow':
          'This category has a low assessment score. Investigate the underlying answers and request supporting evidence.',
      'categoryMedium':
          'This category may need follow-up. Review the identified gaps and verify relevant documents or conditions.',
      'categoryGood':
          'This category scored relatively well. Check supporting evidence before relying on the result.',
      'mandatory': 'Marked mandatory',
      'additional': 'Additional check',
      'evidence':
          'Confirm whether this document applies and obtain or verify the relevant evidence.',
      'disclaimer':
          'This explanation is based on assessment data supplied to HomeSureAI. It is not a legal opinion, independent inspection, document authentication or guarantee of property safety or compliance. Verify important findings with relevant authorities and qualified professionals.',
    },
    'kn': {
      'low':
          'ಮೌಲ್ಯಮಾಪನದಲ್ಲಿ ಎಚ್ಚರಿಕೆಯಿಂದ ಪರಿಶೀಲಿಸಬೇಕಾದ ಅಂಶಗಳು ಕಂಡುಬಂದಿವೆ. ನಿರ್ಧಾರ ಕೈಗೊಳ್ಳುವ ಮೊದಲು ಪ್ರಮುಖ ಅಂಶಗಳನ್ನು ಪರಿಶೀಲಿಸಿ ಮತ್ತು ಸಂಬಂಧಿತ ಸಾಕ್ಷ್ಯಗಳನ್ನು ಪಡೆಯಿರಿ.',
      'medium':
          'ಕೆಲವು ಅಂಶಗಳಿಗೆ ಹೆಚ್ಚಿನ ಪರಿಶೀಲನೆ ಅಗತ್ಯವಿರಬಹುದು. ಪಟ್ಟಿ ಮಾಡಿರುವ ಅಪಾಯಗಳು, ಕಡಿಮೆ ಅಂಕ ಪಡೆದ ವಿಭಾಗಗಳು ಮತ್ತು ಬಾಕಿ ಇರುವ ಸಾಕ್ಷ್ಯಗಳ ಮೇಲೆ ಗಮನಹರಿಸಿ.',
      'positive':
          'ಮೌಲ್ಯಮಾಪನದ ಫಲಿತಾಂಶ ತಕ್ಕಮಟ್ಟಿಗೆ ಉತ್ತಮವಾಗಿದೆ. ಆದರೆ ಅಂಕ ಮಾತ್ರದಿಂದ ಆಸ್ತಿ ಅಥವಾ ದಾಖಲೆಗಳು ಸಂಪೂರ್ಣವಾಗಿ ಪರಿಶೀಲಿತವಾಗಿವೆ ಎಂದು ಖಚಿತಪಡಿಸಲಾಗುವುದಿಲ್ಲ. ಉಳಿದ ಅಂಶಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.',
      'high':
          'ಮೌಲ್ಯಮಾಪನದ ಅಂಕ ಹೆಚ್ಚು ಇದೆ. ಆದರೂ ಆಸ್ತಿ ನಿರ್ಧಾರಕ್ಕೆ ಈ ಫಲಿತಾಂಶವನ್ನು ಬಳಸುವ ಮೊದಲು ದಾಖಲೆಗಳನ್ನು ಪರಿಶೀಲಿಸಿ ಮತ್ತು ಪಟ್ಟಿ ಮಾಡಿರುವ ಅಪಾಯಗಳನ್ನು ಗಮನಿಸಿ.',
      'categoryLow':
          'ಈ ವಿಭಾಗದ ಅಂಕ ಕಡಿಮೆಯಾಗಿದೆ. ಸಂಬಂಧಿತ ಉತ್ತರಗಳನ್ನು ಪರಿಶೀಲಿಸಿ ಮತ್ತು ಬೆಂಬಲಿಸುವ ಸಾಕ್ಷ್ಯಗಳನ್ನು ಕೇಳಿ.',
      'categoryMedium':
          'ಈ ವಿಭಾಗಕ್ಕೆ ಹೆಚ್ಚಿನ ಪರಿಶೀಲನೆ ಬೇಕಾಗಬಹುದು. ಕಂಡುಬಂದ ಕೊರತೆಗಳನ್ನು ಪರಿಶೀಲಿಸಿ ಮತ್ತು ಸಂಬಂಧಿತ ದಾಖಲೆಗಳನ್ನು ದೃಢಪಡಿಸಿ.',
      'categoryGood':
          'ಈ ವಿಭಾಗದ ಅಂಕ ತಕ್ಕಮಟ್ಟಿಗೆ ಉತ್ತಮವಾಗಿದೆ. ಫಲಿತಾಂಶವನ್ನು ನಂಬುವ ಮೊದಲು ಸಾಕ್ಷ್ಯಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.',
      'mandatory': 'ಕಡ್ಡಾಯವೆಂದು ಗುರುತಿಸಲಾಗಿದೆ',
      'additional': 'ಹೆಚ್ಚುವರಿ ಪರಿಶೀಲನೆ',
      'evidence':
          'ಈ ದಾಖಲೆ ಅನ್ವಯಿಸುತ್ತದೆಯೇ ಎಂದು ದೃಢಪಡಿಸಿ ಮತ್ತು ಸಂಬಂಧಿತ ಸಾಕ್ಷ್ಯವನ್ನು ಪಡೆಯಿರಿ ಅಥವಾ ಪರಿಶೀಲಿಸಿ.',
      'disclaimer':
          'ಈ ವಿವರಣೆ HomeSureAI ಗೆ ನೀಡಲಾದ ಮೌಲ್ಯಮಾಪನದ ಮಾಹಿತಿಯನ್ನು ಆಧರಿಸಿದೆ. ಇದು ಕಾನೂನು ಅಭಿಪ್ರಾಯ, ಸ್ವತಂತ್ರ ತಪಾಸಣೆ, ದಾಖಲೆಗಳ ದೃಢೀಕರಣ ಅಥವಾ ಆಸ್ತಿಯ ಸುರಕ್ಷತೆ/ಅನುಸರಣೆಯ ಖಾತರಿ ಅಲ್ಲ. ಪ್ರಮುಖ ಅಂಶಗಳನ್ನು ಸಂಬಂಧಿತ ಅಧಿಕಾರಿಗಳು ಮತ್ತು ಅರ್ಹ ತಜ್ಞರೊಂದಿಗೆ ಪರಿಶೀಲಿಸಿ.',
    },
    'hi': {
      'low':
          'मूल्यांकन में कुछ ऐसे क्षेत्र सामने आए हैं जिनकी सावधानी से जाँच ज़रूरी है। निर्णय लेने से पहले प्रमुख निष्कर्षों की समीक्षा करें और सहायक प्रमाण प्राप्त करें।',
      'medium':
          'मूल्यांकन में कुछ ऐसे क्षेत्र हैं जिनकी आगे जाँच की आवश्यकता हो सकती है। सूचीबद्ध जोखिमों, कम अंक वाले वर्गों और लंबित प्रमाणों पर ध्यान दें।',
      'positive':
          'मूल्यांकन का परिणाम अपेक्षाकृत अच्छा है, लेकिन केवल स्कोर से यह साबित नहीं होता कि संपत्ति या उसके दस्तावेज़ पूरी तरह सत्यापित हैं। बाकी निष्कर्षों की समीक्षा करें।',
      'high':
          'मूल्यांकन का स्कोर ऊँचा है। फिर भी संपत्ति से जुड़ा निर्णय लेने से पहले दस्तावेज़ों की जाँच करें और सूचीबद्ध जोखिमों की समीक्षा करें।',
      'categoryLow':
          'इस वर्ग का मूल्यांकन स्कोर कम है। संबंधित उत्तरों की जाँच करें और सहायक प्रमाण माँगें।',
      'categoryMedium':
          'इस वर्ग में आगे जाँच की आवश्यकता हो सकती है। पहचानी गई कमियों और संबंधित दस्तावेज़ों की समीक्षा करें।',
      'categoryGood':
          'इस वर्ग का स्कोर अपेक्षाकृत अच्छा है। परिणाम पर भरोसा करने से पहले प्रमाणों की जाँच करें।',
      'mandatory': 'अनिवार्य चिह्नित',
      'additional': 'अतिरिक्त जाँच',
      'evidence':
          'पुष्टि करें कि यह दस्तावेज़ लागू होता है या नहीं, और संबंधित प्रमाण प्राप्त करें या सत्यापित करें।',
      'disclaimer':
          'यह व्याख्या HomeSureAI को दिए गए मूल्यांकन डेटा पर आधारित है। यह कानूनी राय, स्वतंत्र निरीक्षण, दस्तावेज़ प्रमाणीकरण या संपत्ति की सुरक्षा अथवा अनुपालन की गारंटी नहीं है। महत्वपूर्ण निष्कर्षों की संबंधित अधिकारियों और योग्य विशेषज्ञों से पुष्टि करें।',
    },
    'te': {
      'low':
          'మూల్యాంకనంలో జాగ్రత్తగా పరిశీలించాల్సిన అంశాలు కనిపించాయి. నిర్ణయం తీసుకునే ముందు ముఖ్యమైన అంశాలను సమీక్షించి, ఆధారాలను పొందండి.',
      'medium':
          'కొన్ని అంశాలకు మరింత పరిశీలన అవసరం కావచ్చు. జాబితాలోని ప్రమాదాలు, తక్కువ స్కోరు ఉన్న విభాగాలు, పెండింగ్ ఆధారాలపై దృష్టి పెట్టండి.',
      'positive':
          'మూల్యాంకన ఫలితం తగినంత సానుకూలంగా ఉంది. అయితే స్కోరు మాత్రమే ఆస్తి లేదా పత్రాలు పూర్తిగా ధృవీకరించబడ్డాయని నిరూపించదు. మిగిలిన అంశాలను పరిశీలించండి.',
      'high':
          'మూల్యాంకన స్కోరు ఎక్కువగా ఉంది. అయినప్పటికీ ఆస్తి గురించి నిర్ణయం తీసుకునే ముందు పత్రాలను తనిఖీ చేసి, జాబితాలోని ప్రమాదాలను పరిశీలించండి.',
      'categoryLow':
          'ఈ విభాగం స్కోరు తక్కువగా ఉంది. సంబంధిత సమాధానాలను పరిశీలించి ఆధారాలు కోరండి.',
      'categoryMedium':
          'ఈ విభాగానికి మరింత పరిశీలన అవసరం కావచ్చు. గుర్తించిన లోపాలను, సంబంధిత పత్రాలను తనిఖీ చేయండి.',
      'categoryGood':
          'ఈ విభాగం స్కోరు తగినంత బాగుంది. ఫలితంపై ఆధారపడే ముందు ఆధారాలను పరిశీలించండి.',
      'mandatory': 'తప్పనిసరిగా గుర్తించబడింది',
      'additional': 'అదనపు తనిఖీ',
      'evidence':
          'ఈ పత్రం వర్తిస్తుందో లేదో నిర్ధారించి, సంబంధిత ఆధారాన్ని పొందండి లేదా ధృవీకరించండి.',
      'disclaimer':
          'ఈ వివరణ HomeSureAIకి అందించిన మూల్యాంకన డేటాపై ఆధారపడింది. ఇది న్యాయ సలహా, స్వతంత్ర తనిఖీ, పత్రాల ప్రామాణీకరణ లేదా ఆస్తి భద్రత/అనుసరణకు హామీ కాదు. ముఖ్యమైన అంశాలను సంబంధిత అధికారులతో మరియు అర్హత కలిగిన నిపుణులతో నిర్ధారించండి.',
    },
    'ta': {
      'low':
          'மதிப்பீட்டில் கவனமாக ஆய்வு செய்ய வேண்டிய அம்சங்கள் உள்ளன. முடிவு எடுப்பதற்கு முன் முக்கிய கண்டறிதல்களைப் பார்த்து ஆதாரங்களைப் பெறுங்கள்.',
      'medium':
          'சில அம்சங்களுக்கு மேலும் ஆய்வு தேவைப்படலாம். பட்டியலிடப்பட்ட அபாயங்கள், குறைந்த மதிப்பெண் பெற்ற பிரிவுகள் மற்றும் நிலுவை ஆதாரங்களில் கவனம் செலுத்துங்கள்.',
      'positive':
          'மதிப்பீடு ஒப்பீட்டளவில் நல்லதாக உள்ளது. ஆனால் மதிப்பெண் மட்டும் சொத்து அல்லது ஆவணங்கள் முழுமையாகச் சரிபார்க்கப்பட்டதை நிரூபிக்காது. மீதமுள்ள அம்சங்களை ஆய்வு செய்யுங்கள்.',
      'high':
          'மதிப்பீட்டு மதிப்பெண் அதிகமாக உள்ளது. இருப்பினும் சொத்து முடிவெடுப்பதற்கு முன் ஆவணங்களையும் பட்டியலிடப்பட்ட அபாயங்களையும் சரிபார்க்கவும்.',
      'categoryLow':
          'இந்தப் பிரிவின் மதிப்பெண் குறைவாக உள்ளது. தொடர்புடைய பதில்களை ஆய்வு செய்து ஆதாரங்களைக் கோருங்கள்.',
      'categoryMedium':
          'இந்தப் பிரிவுக்கு மேலும் ஆய்வு தேவைப்படலாம். கண்டறியப்பட்ட குறைபாடுகளையும் தொடர்புடைய ஆவணங்களையும் சரிபார்க்கவும்.',
      'categoryGood':
          'இந்தப் பிரிவின் மதிப்பெண் ஒப்பீட்டளவில் நன்றாக உள்ளது. முடிவை நம்புவதற்கு முன் ஆதாரங்களைச் சரிபார்க்கவும்.',
      'mandatory': 'கட்டாயம் எனக் குறிக்கப்பட்டது',
      'additional': 'கூடுதல் சரிபார்ப்பு',
      'evidence':
          'இந்த ஆவணம் பொருந்துமா என்பதை உறுதிசெய்து, தொடர்புடைய ஆதாரத்தைப் பெறவும் அல்லது சரிபார்க்கவும்.',
      'disclaimer':
          'இந்த விளக்கம் HomeSureAI-க்கு வழங்கப்பட்ட மதிப்பீட்டுத் தரவை அடிப்படையாகக் கொண்டது. இது சட்ட ஆலோசனை, சுயாதீன ஆய்வு, ஆவண அங்கீகாரம் அல்லது சொத்தின் பாதுகாப்பு/இணக்கத்திற்கான உத்தரவாதம் அல்ல. முக்கிய அம்சங்களை சம்பந்தப்பட்ட அதிகாரிகள் மற்றும் தகுதியான நிபுணர்களிடம் சரிபார்க்கவும்.',
    },
    'ml': {
      'low':
          'ശ്രദ്ധാപൂർവം പരിശോധിക്കേണ്ട ചില കാര്യങ്ങൾ വിലയിരുത്തലിൽ കണ്ടെത്തിയിട്ടുണ്ട്. തീരുമാനമെടുക്കുന്നതിന് മുമ്പ് പ്രധാന കണ്ടെത്തലുകൾ പരിശോധിച്ച് തെളിവുകൾ നേടുക.',
      'medium':
          'ചില കാര്യങ്ങളിൽ കൂടുതൽ പരിശോധന ആവശ്യമായേക്കാം. പട്ടികപ്പെടുത്തിയ അപകടസാധ്യതകൾ, കുറഞ്ഞ സ്കോർ നേടിയ വിഭാഗങ്ങൾ, ലഭിക്കാനുള്ള തെളിവുകൾ എന്നിവ ശ്രദ്ധിക്കുക.',
      'positive':
          'വിലയിരുത്തൽ താരതമ്യേന നല്ലതാണ്. എന്നാൽ സ്കോർ മാത്രം കൊണ്ട് സ്വത്തോ രേഖകളോ പൂർണമായി പരിശോധിച്ചതായി ഉറപ്പിക്കാനാവില്ല. ശേഷിക്കുന്ന കാര്യങ്ങൾ പരിശോധിക്കുക.',
      'high':
          'വിലയിരുത്തൽ സ്കോർ ഉയർന്നതാണ്. എന്നിരുന്നാലും സ്വത്ത് സംബന്ധിച്ച തീരുമാനം എടുക്കുന്നതിന് മുമ്പ് രേഖകളും പട്ടികപ്പെടുത്തിയ അപകടസാധ്യതകളും പരിശോധിക്കുക.',
      'categoryLow':
          'ഈ വിഭാഗത്തിന്റെ സ്കോർ കുറവാണ്. ബന്ധപ്പെട്ട ഉത്തരങ്ങൾ പരിശോധിച്ച് പിന്തുണയ്ക്കുന്ന തെളിവുകൾ ആവശ്യപ്പെടുക.',
      'categoryMedium':
          'ഈ വിഭാഗത്തിന് കൂടുതൽ പരിശോധന ആവശ്യമായേക്കാം. കണ്ടെത്തിയ കുറവുകളും ബന്ധപ്പെട്ട രേഖകളും പരിശോധിക്കുക.',
      'categoryGood':
          'ഈ വിഭാഗത്തിന്റെ സ്കോർ താരതമ്യേന നല്ലതാണ്. ഫലത്തെ ആശ്രയിക്കുന്നതിന് മുമ്പ് തെളിവുകൾ പരിശോധിക്കുക.',
      'mandatory': 'നിർബന്ധമെന്ന് അടയാളപ്പെടുത്തി',
      'additional': 'കൂടുതൽ പരിശോധന',
      'evidence':
          'ഈ രേഖ ബാധകമാണോ എന്ന് ഉറപ്പാക്കി ബന്ധപ്പെട്ട തെളിവ് നേടുകയോ പരിശോധിക്കുകയോ ചെയ്യുക.',
      'disclaimer':
          'ഈ വിശദീകരണം HomeSureAI-ക്ക് നൽകിയ വിലയിരുത്തൽ വിവരങ്ങളെ അടിസ്ഥാനമാക്കിയുള്ളതാണ്. ഇത് നിയമോപദേശം, സ്വതന്ത്ര പരിശോധന, രേഖകളുടെ ആധികാരികത ഉറപ്പാക്കൽ, അല്ലെങ്കിൽ സ്വത്തിന്റെ സുരക്ഷയ്ക്കും നിയമാനുസൃതതയ്ക്കുമുള്ള ഉറപ്പല്ല. പ്രധാന കണ്ടെത്തലുകൾ ബന്ധപ്പെട്ട അധികാരികളുമായും യോഗ്യതയുള്ള വിദഗ്ധരുമായും പരിശോധിക്കുക.',
    },
  };

  String _text(String language, String key) =>
      _copy[language]?[key] ?? _copy['en']![key]!;

  PropertyHealthExplanation explain(
    PropertyHealthReport report, {
    String languageCode = 'en',
  }) {
    final language = supportedLanguages.contains(languageCode)
        ? languageCode
        : 'en';
    final score = report.assessment.overallScore;

    final categories = report.assessment.categoryResults.toList()
      ..sort((a, b) => a.percentage.compareTo(b.percentage));

    final categoryExplanations = categories
        .map((category) {
          final percentage = category.percentage;
          final key = percentage < 50
              ? 'categoryLow'
              : percentage < 70
              ? 'categoryMedium'
              : 'categoryGood';

          return ExplainedCategory(
            name: category.category.displayName,
            score: percentage,
            explanation: _text(language, key),
          );
        })
        .toList(growable: false);

    final summaryKey = score < 50
        ? 'low'
        : score < 70
        ? 'medium'
        : score < 85
        ? 'positive'
        : 'high';

    final priorityActions = report.recommendations
        .map((item) => '${item.title}: ${item.description}')
        .toList(growable: false);

    final missingEvidence = report.missingDocuments
        .map((document) {
          final importance = _text(
            language,
            document.mandatory ? 'mandatory' : 'additional',
          );
          return '$importance: ${document.name}. ${_text(language, 'evidence')}';
        })
        .toList(growable: false);

    final riskExplanations = report.risks
        .map((risk) {
          final severity = risk.severity.name.toUpperCase();
          return '$severity — ${risk.title}: ${risk.description}';
        })
        .toList(growable: false);

    return PropertyHealthExplanation(
      propertyName: report.propertyName,
      score: score,
      summary: _text(language, summaryKey),
      categories: categoryExplanations,
      risks: riskExplanations,
      priorityActions: priorityActions,
      missingEvidence: missingEvidence,
      disclaimer: _text(language, 'disclaimer'),
    );
  }
}

class PropertyHealthExplanation {
  final String propertyName;
  final double score;
  final String summary;
  final List<ExplainedCategory> categories;
  final List<String> risks;
  final List<String> priorityActions;
  final List<String> missingEvidence;
  final String disclaimer;

  const PropertyHealthExplanation({
    required this.propertyName,
    required this.score,
    required this.summary,
    required this.categories,
    required this.risks,
    required this.priorityActions,
    required this.missingEvidence,
    required this.disclaimer,
  });
}

class ExplainedCategory {
  final String name;
  final double score;
  final String explanation;

  const ExplainedCategory({
    required this.name,
    required this.score,
    required this.explanation,
  });
}
