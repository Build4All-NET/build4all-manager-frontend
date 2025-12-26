// runtime_presets.dart
// Simple "palette" presets so owners pick configs instead of pasting base64.

class RuntimePreset {
  final String id;
  final String label;
  final String json; // raw JSON string (backend will b64 it for CI)
  const RuntimePreset(this.id, this.label, this.json);
}

class RuntimePresets {
  static const navPresets = <RuntimePreset>[
    RuntimePreset(
      'nav_bottom_shop',
      'Bottom Nav (Shop)',
      '''
[
  {"id":"home","label":"Home","icon":"home"},
  {"id":"explore","label":"Explore","icon":"search"},
  {"id":"cart","label":"Cart","icon":"shopping_cart"},
  {"id":"profile","label":"Profile","icon":"person"}
]
''',
    ),
    RuntimePreset(
      'nav_bottom_services',
      'Bottom Nav (Services)',
      '''
[
  {"id":"home","label":"Home","icon":"home"},
  {"id":"services","label":"Services","icon":"handyman"},
  {"id":"orders","label":"Orders","icon":"receipt_long"},
  {"id":"profile","label":"Profile","icon":"person"}
]
''',
    ),
  ];

  static const featuresPresets = <RuntimePreset>[
    RuntimePreset('feat_ecommerce_core', 'E-commerce Core', '''
["ITEMS","CART","ORDERS","REVIEWS"]
'''),
    RuntimePreset('feat_services_core', 'Services Core', '''
["SERVICES","BOOKING","REVIEWS","CHAT"]
'''),
    RuntimePreset('feat_full', 'Full (Everything)', '''
["ITEMS","CART","ORDERS","BOOKING","REVIEWS","CHAT","NOTIFICATIONS"]
'''),
  ];

  static const homePresets = <RuntimePreset>[
    RuntimePreset(
      'home_shop_default',
      'Home (Shop Default)',
      '''
{
  "sections":[
    {"id":"header","type":"HEADER","layout":"full","limit":1},
    {"id":"search","type":"SEARCH","layout":"full","limit":1},
    {"id":"hero_banner","type":"BANNER","layout":"full","limit":1},
    {"id":"categories","type":"CATEGORY_CHIPS","layout":"horizontal","limit":10},
    {"id":"flash_sale","type":"ITEM_LIST","feature":"ITEMS","layout":"horizontal","limit":10},
    {"id":"new_arrivals","type":"ITEM_LIST","feature":"ITEMS","layout":"vertical","limit":10}
  ]
}
''',
    ),
    RuntimePreset(
      'home_services_default',
      'Home (Services Default)',
      '''
{
  "sections":[
    {"id":"header","type":"HEADER","layout":"full","limit":1},
    {"id":"search","type":"SEARCH","layout":"full","limit":1},
    {"id":"featured","type":"SERVICE_LIST","feature":"SERVICES","layout":"horizontal","limit":10},
    {"id":"top_rated","type":"SERVICE_LIST","feature":"SERVICES","layout":"vertical","limit":10},
    {"id":"reviews","type":"REVIEW_LIST","feature":"REVIEWS","layout":"vertical","limit":4}
  ]
}
''',
    ),
  ];

  static const brandingPresets = <RuntimePreset>[
    RuntimePreset(
      'brand_default_light',
      'Branding (Light)',
      '''
{
  "splashColor":"#FFFFFF",
  "logoShape":"rounded",
  "logoPadding":10
}
''',
    ),
    RuntimePreset(
      'brand_dark',
      'Branding (Dark)',
      '''
{
  "splashColor":"#0B0F14",
  "logoShape":"rounded",
  "logoPadding":10
}
''',
    ),
  ];
}
