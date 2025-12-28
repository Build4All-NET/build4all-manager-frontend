class RuntimePreset {
  final String id;
  final String label;
  final String json; // RAW JSON string
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
    {"id":"flash_sale","type":"ITEM_LIST","feature":"ITEMS","layout":"horizontal","limit":10}
  ]
}
''',
    ),
  ];

  static const featuresPresets = <RuntimePreset>[
    RuntimePreset('feat_ecommerce', 'E-commerce Core', '''
["ITEMS","BOOKING","REVIEWS","ORDERS"]
'''),
  ];

  static const brandingPresets = <RuntimePreset>[
    RuntimePreset('brand_light', 'Branding (Light)', '''
{ "splashColor": "#FFFFFF" }
'''),
  ];
}
