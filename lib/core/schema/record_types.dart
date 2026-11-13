// Schema-driven record definitions for every section of the blueprint.
// Adding a new record type here gives it list, detail, form, encryption,
// search and assistant support automatically.

import 'package:flutter/material.dart';

import '../crypto/key_manager.dart';
import '../models/record.dart';

enum FieldType { text, multiline, number, money, percent, date, choice, email, phone, toggle, ref }

class FieldSpec {
  const FieldSpec(
    this.key,
    this.label,
    this.type, {
    this.required = false,
    this.options = const [],
    this.hint,
    this.refKinds = const [],
    this.defaultValue,
    this.sensitive = false,
    this.showIf,
  });

  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final List<String> options;
  final String? hint;
  final List<String> refKinds;
  final Object? defaultValue;

  /// Masked in detail views until tapped (IDs, account references).
  final bool sensitive;

  /// Only shown (and saved) when the field named `$1` has one of the values in `$2`.
  final (String, List<String>)? showIf;

  bool visibleWith(Map<String, dynamic> values) {
    final c = showIf;
    return c == null || c.$2.contains(values[c.$1]);
  }
}

class RecordType {
  const RecordType({
    required this.kind,
    required this.category,
    required this.label,
    required this.plural,
    required this.icon,
    required this.fields,
    this.titleKey = 'name',
    this.subtitleKeys = const [],
    this.singleton = false,
    this.description,
    this.hidden = false,
  });

  final String kind;
  final String category;
  final String label;
  final String plural;
  final IconData icon;
  final List<FieldSpec> fields;
  final String titleKey;
  final List<String> subtitleKeys;
  final bool singleton;
  final String? description;

  /// Managed by a dedicated screen rather than the generic list (e.g. allocations).
  final bool hidden;

  String title(DossierRecord r) {
    final t = r.str(titleKey);
    return t.isEmpty ? 'Untitled $label' : t;
  }

  FieldSpec? field(String key) {
    for (final f in fields) {
      if (f.key == key) return f;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Shared option lists
// ---------------------------------------------------------------------------

const currencies = ['GHS', 'USD', 'GBP', 'EUR', 'NGN', 'XOF', 'ZAR', 'KES', 'CAD', 'CNY', 'AED'];

const ownershipEvidence = [
  'Self-declared',
  'Supporting document attached',
  'Professionally verified',
];

const relationships = [
  'Spouse',
  'Child',
  'Parent',
  'Sibling',
  'Grandparent',
  'Grandchild',
  'Aunt / Uncle',
  'Niece / Nephew',
  'Cousin',
  'In-law',
  'Friend',
  'Business partner',
  'Lawyer',
  'Accountant',
  'Financial adviser',
  'Charity / Organisation',
  'Other',
];

FieldSpec _currency() => const FieldSpec('currency', 'Currency', FieldType.choice, options: currencies, defaultValue: 'GHS');
FieldSpec _value(String label) => FieldSpec('value', label, FieldType.money);
FieldSpec _ownership() => const FieldSpec('ownership', 'Your ownership %', FieldType.percent, defaultValue: 100);
FieldSpec _evidence() => const FieldSpec('evidence', 'Ownership evidence', FieldType.choice,
    options: ownershipEvidence, defaultValue: 'Self-declared');
// ---- Succession message timing ----
const deliverOnRelease = 'As soon as access is released';
const deliverAfterDelay = 'A set time after release';
const deliverOnDate = 'On a specific date';
const deliveryModes = [deliverOnRelease, deliverAfterDelay, deliverOnDate];
const delayUnits = ['Days', 'Weeks', 'Months', 'Years'];

// ---- Paying in installments (land, cars, etc.) ----
const paymentFullyPaid = 'Fully paid';
const paymentInstallments = 'Paying in installments';
const _inst = ('paymentStatus', [paymentInstallments]);

/// Payment status and, when still paying, the amount paid and balance left.
/// The outstanding balance counts as a liability in net worth.
List<FieldSpec> _installments() => const [
      FieldSpec('paymentStatus', 'Payment status', FieldType.choice,
          options: [paymentFullyPaid, paymentInstallments], defaultValue: paymentFullyPaid),
      FieldSpec('amountPaid', 'Amount paid so far', FieldType.money, showIf: _inst),
      FieldSpec('balance', 'Outstanding balance', FieldType.money,
          showIf: _inst, hint: 'Leave blank to work it out from the price minus the amount paid'),
      FieldSpec('installmentAmount', 'Installment amount', FieldType.money, showIf: _inst),
      FieldSpec('installmentFrequency', 'Paid every', FieldType.choice,
          showIf: _inst, options: ['Week', 'Month', 'Quarter', '6 months', 'Year', 'Irregular']),
      FieldSpec('nextPaymentDate', 'Next payment due', FieldType.date, showIf: _inst),
      FieldSpec('finalPaymentDate', 'Expected final payment', FieldType.date, showIf: _inst),
      FieldSpec('paidTo', 'Paid to (seller, developer or lender)', FieldType.text, showIf: _inst),
    ];

FieldSpec _notes() => const FieldSpec('notes', 'Notes', FieldType.multiline);
FieldSpec _succession() =>
    const FieldSpec('successionNotes', 'Intended distribution / succession instructions', FieldType.multiline);

// ---------------------------------------------------------------------------
// Kinds
// ---------------------------------------------------------------------------

class Kinds {
  // Life
  static const profile = 'profile';
  static const education = 'education';
  static const career = 'career';
  static const achievement = 'achievement';
  static const lifeEvent = 'life_event';
  static const value = 'value';
  // Wealth
  static const property = 'property';
  static const vehicle = 'vehicle';
  static const financialAccount = 'financial_account';
  static const business = 'business';
  static const valuable = 'valuable';
  static const digitalAsset = 'digital_asset';
  static const liability = 'liability';
  static const insurance = 'insurance';
  // Vault
  static const document = 'document';
  // Legacy
  static const beneficiary = 'beneficiary';
  static const allocation = 'allocation';
  static const executor = 'executor';
  static const wish = 'wish';
  static const willVersion = 'will_version';
  static const legacyMessage = 'legacy_message';
  // Family
  static const familyMember = 'family_member';
  static const familyStory = 'family_story';
  // Succession
  static const confidant = 'confidant';
  static const estateProgress = 'estate_progress';

  /// Records that count towards net worth and need beneficiary instructions.
  static const assets = [property, vehicle, financialAccount, business, valuable, digitalAsset];
}

final Map<String, RecordType> recordTypes = {
  for (final t in _types) t.kind: t,
};

RecordType typeOf(String kind) =>
    recordTypes[kind] ?? (throw ArgumentError('Unknown record kind "$kind"'));

List<RecordType> typesIn(String category) =>
    _types.where((t) => t.category == category && !t.hidden).toList();

final List<RecordType> _types = [
  // ======================= PILLAR 1: MY LIFE =======================
  const RecordType(
    kind: Kinds.profile,
    category: Categories.life,
    label: 'Personal profile',
    plural: 'Personal profile',
    icon: Icons.badge_outlined,
    singleton: true,
    titleKey: 'legalName',
    subtitleKeys: ['occupation', 'nationality'],
    fields: [
      FieldSpec('legalName', 'Full legal name', FieldType.text, required: true),
      FieldSpec('preferredName', 'Preferred name', FieldType.text),
      FieldSpec('dateOfBirth', 'Date of birth', FieldType.date),
      FieldSpec('placeOfBirth', 'Place of birth', FieldType.text),
      FieldSpec('nationality', 'Nationality', FieldType.text, defaultValue: 'Ghanaian'),
      FieldSpec('address', 'Residential address / GhanaPost GPS', FieldType.multiline),
      FieldSpec('phone', 'Phone', FieldType.phone),
      FieldSpec('email', 'Email', FieldType.email),
      FieldSpec('emergencyContacts', 'Emergency contacts', FieldType.multiline),
      FieldSpec('idType', 'Identification type', FieldType.choice,
          options: ['Ghana Card', 'Passport', "Driver's licence", "Voter's ID", 'Other']),
      FieldSpec('idNumber', 'Identification number', FieldType.text, sensitive: true),
      FieldSpec('maritalStatus', 'Marital status', FieldType.choice,
          options: ['Single', 'Married (ordinance)', 'Married (customary)', 'Married (Islamic)', 'Divorced', 'Widowed', 'Separated']),
      FieldSpec('languages', 'Languages', FieldType.text),
      FieldSpec('occupation', 'Occupation', FieldType.text),
      FieldSpec('biography', 'Personal biography', FieldType.multiline),
    ],
  ),
  const RecordType(
    kind: Kinds.education,
    category: Categories.life,
    label: 'Education record',
    plural: 'Education & qualifications',
    icon: Icons.school_outlined,
    titleKey: 'qualification',
    subtitleKeys: ['institution', 'endDate'],
    fields: [
      FieldSpec('level', 'Level', FieldType.choice, required: true, options: [
        'Primary',
        'Secondary / SHS',
        'University',
        'Professional qualification',
        'Training / certification',
        'Academic award',
        'Scholarship',
        'Professional membership',
      ]),
      FieldSpec('qualification', 'Qualification / title', FieldType.text, required: true, hint: 'e.g. BSc Computer Science, ACCA, WASSCE'),
      FieldSpec('institution', 'Institution', FieldType.text),
      FieldSpec('startDate', 'Start date', FieldType.date),
      FieldSpec('endDate', 'Completion date', FieldType.date),
      FieldSpec('description', 'Description', FieldType.multiline),
    ],
  ),
  const RecordType(
    kind: Kinds.career,
    category: Categories.life,
    label: 'Career entry',
    plural: 'Career history',
    icon: Icons.work_outline,
    titleKey: 'position',
    subtitleKeys: ['organisation', 'startDate'],
    fields: [
      FieldSpec('position', 'Position', FieldType.text, required: true),
      FieldSpec('organisation', 'Organisation', FieldType.text, required: true),
      FieldSpec('current', 'Current role', FieldType.toggle),
      FieldSpec('startDate', 'Start date', FieldType.date),
      FieldSpec('endDate', 'End date', FieldType.date),
      FieldSpec('milestones', 'Milestones, projects & achievements', FieldType.multiline),
      FieldSpec('references', 'Professional references', FieldType.multiline),
    ],
  ),
  const RecordType(
    kind: Kinds.achievement,
    category: Categories.life,
    label: 'Achievement',
    plural: 'Achievements & recognition',
    icon: Icons.emoji_events_outlined,
    titleKey: 'title',
    subtitleKeys: ['type', 'date'],
    fields: [
      FieldSpec('title', 'Title', FieldType.text, required: true),
      FieldSpec('type', 'Type', FieldType.choice, options: [
        'Award',
        'Honour',
        'Publication',
        'Patent / invention',
        'Community contribution',
        'Leadership position',
        'Professional accomplishment',
        'Sporting achievement',
        'Philanthropy',
      ]),
      FieldSpec('date', 'Date', FieldType.date),
      FieldSpec('awardedBy', 'Awarded by / organisation', FieldType.text),
      FieldSpec('description', 'Description', FieldType.multiline),
    ],
  ),
  const RecordType(
    kind: Kinds.lifeEvent,
    category: Categories.life,
    label: 'Life event',
    plural: 'Life events',
    icon: Icons.timeline,
    titleKey: 'title',
    subtitleKeys: ['date'],
    fields: [
      FieldSpec('title', 'Event', FieldType.text, required: true, hint: 'e.g. Married Ama, Bought first land'),
      FieldSpec('date', 'Date', FieldType.date, required: true),
      FieldSpec('type', 'Type', FieldType.choice, options: [
        'Birth',
        'Education',
        'Graduation',
        'Employment',
        'Marriage',
        'Birth of child',
        'Business',
        'Property',
        'Award',
        'Retirement',
        'Other',
      ]),
      FieldSpec('description', 'Story', FieldType.multiline),
    ],
  ),
  const RecordType(
    kind: Kinds.value,
    category: Categories.life,
    label: 'Value or interest',
    plural: 'Interests & values',
    icon: Icons.favorite_border,
    titleKey: 'title',
    subtitleKeys: ['type'],
    fields: [
      FieldSpec('type', 'Type', FieldType.choice, required: true, options: [
        'Personal philosophy',
        'Religious / cultural preference',
        'Personal value',
        'Favourite activity',
        'Important relationship',
        'Cause I support',
        'Life lesson',
      ]),
      FieldSpec('title', 'Title', FieldType.text, required: true),
      FieldSpec('details', 'Details', FieldType.multiline),
    ],
  ),

  // ======================= PILLAR 2: MY WEALTH =======================
  RecordType(
    kind: Kinds.property,
    category: Categories.wealth,
    label: 'Property',
    plural: 'Real estate & land',
    icon: Icons.home_work_outlined,
    subtitleKeys: const ['propertyType', 'location'],
    fields: [
      const FieldSpec('name', 'Property name', FieldType.text, required: true, hint: 'e.g. East Legon family house'),
      const FieldSpec('propertyType', 'Type', FieldType.choice, required: true, options: [
        'Residential',
        'Commercial building',
        'Land',
        'Farm',
        'Rental property',
        'Vacation home',
        'International property',
        'Inherited / family property',
      ]),
      const FieldSpec('location', 'Location / GPS address', FieldType.multiline),
      const FieldSpec('acquisitionDate', 'Acquisition date', FieldType.date),
      const FieldSpec('acquisitionPrice', 'Acquisition price', FieldType.money),
      _value('Estimated current value'),
      _currency(),
      ..._installments(),
      const FieldSpec('ownershipStructure', 'Ownership structure', FieldType.choice,
          options: ['Sole', 'Joint', 'Family / stool land', 'Company', 'Trust', 'Leasehold', 'Other']),
      _ownership(),
      const FieldSpec('coOwners', 'Co-owners', FieldType.text),
      const FieldSpec('titleRef', 'Title / lease / indenture reference', FieldType.text, sensitive: true),
      const FieldSpec('liabilities', 'Mortgage or outstanding liabilities', FieldType.text),
      _evidence(),
      const FieldSpec('description', 'Description', FieldType.multiline),
      _succession(),
    ],
  ),
  RecordType(
    kind: Kinds.vehicle,
    category: Categories.wealth,
    label: 'Vehicle',
    plural: 'Vehicles & transport',
    icon: Icons.directions_car_outlined,
    subtitleKeys: const ['vehicleType', 'registration'],
    fields: [
      const FieldSpec('name', 'Make & model', FieldType.text, required: true),
      const FieldSpec('vehicleType', 'Type', FieldType.choice,
          options: ['Car', 'Motorcycle', 'Truck', 'Commercial vehicle', 'Boat', 'Aircraft', 'Other']),
      const FieldSpec('registration', 'Registration number', FieldType.text),
      const FieldSpec('chassis', 'Chassis / VIN', FieldType.text, sensitive: true),
      const FieldSpec('purchaseDate', 'Purchase date', FieldType.date),
      const FieldSpec('purchasePrice', 'Purchase price', FieldType.money),
      _value('Current estimated value'),
      _currency(),
      ..._installments(),
      _ownership(),
      const FieldSpec('insurance', 'Insurance details', FieldType.text),
      const FieldSpec('loan', 'Loan information', FieldType.text),
      const FieldSpec('roadworthyExpiry', 'Roadworthy / licence expiry', FieldType.date),
      _evidence(),
      _succession(),
    ],
  ),
  RecordType(
    kind: Kinds.financialAccount,
    category: Categories.wealth,
    label: 'Financial asset',
    plural: 'Bank & financial assets',
    icon: Icons.account_balance_outlined,
    subtitleKeys: const ['accountType', 'institution'],
    description:
        'Record the institution and a masked reference only. Never store PINs, passwords or transaction codes here.',
    fields: [
      const FieldSpec('name', 'Name', FieldType.text, required: true, hint: 'e.g. Main savings'),
      const FieldSpec('accountType', 'Type', FieldType.choice, required: true, options: [
        'Current account',
        'Savings',
        'Fixed deposit',
        'Investment portfolio',
        'Shares',
        'Bonds',
        'Mutual fund',
        'Treasury bills',
        'Retirement / Tier 2 / Tier 3 pension',
        'Mobile money wallet',
        'Foreign currency holding',
        'Other',
      ]),
      const FieldSpec('institution', 'Institution', FieldType.text, required: true),
      const FieldSpec('maskedRef', 'Account reference (last 4 digits only)', FieldType.text,
          hint: 'e.g. ****4417', sensitive: true),
      const FieldSpec('branch', 'Branch / relationship manager contact', FieldType.text),
      _value('Approximate balance / value'),
      _currency(),
      _ownership(),
      const FieldSpec('productNominee', 'Nominee registered with the institution', FieldType.text,
          hint: 'Product nominations may differ from your will'),
      _evidence(),
      _succession(),
    ],
  ),
  RecordType(
    kind: Kinds.business,
    category: Categories.wealth,
    label: 'Business interest',
    plural: 'Businesses & investments',
    icon: Icons.storefront_outlined,
    subtitleKeys: const ['role', 'industry'],
    fields: [
      const FieldSpec('name', 'Business name', FieldType.text, required: true),
      const FieldSpec('role', 'Your interest', FieldType.choice, options: [
        'Founder',
        'Co-owner',
        'Shareholder',
        'Director',
        'Partner',
        'Sole proprietor',
        'Intellectual property owner',
        'Investor',
      ]),
      const FieldSpec('registration', 'Registration details (ORC / TIN)', FieldType.text, sensitive: true),
      const FieldSpec('industry', 'Industry', FieldType.text),
      _ownership(),
      const FieldSpec('partners', 'Partners & shareholders', FieldType.multiline),
      _value('Estimated valuation of your share'),
      _currency(),
      ..._installments(),
      const FieldSpec('premises', 'Business premises', FieldType.text),
      const FieldSpec('keyContacts', 'Key contacts', FieldType.multiline),
      const FieldSpec('obligations', 'Outstanding obligations', FieldType.multiline),
      const FieldSpec('continuity', 'Business continuity preferences', FieldType.multiline),
      _evidence(),
      _succession(),
    ],
  ),
  RecordType(
    kind: Kinds.valuable,
    category: Categories.wealth,
    label: 'Valuable',
    plural: 'Valuables & personal assets',
    icon: Icons.diamond_outlined,
    subtitleKeys: const ['valuableType'],
    fields: [
      const FieldSpec('name', 'Item', FieldType.text, required: true),
      const FieldSpec('valuableType', 'Type', FieldType.choice, options: [
        'Jewellery',
        'Watch',
        'Artwork',
        'Antique',
        'Collectible',
        'Furniture',
        'Precious metals',
        'Kente / heirloom textile',
        'Luxury goods',
        'Equipment',
        'Other',
      ]),
      const FieldSpec('storedAt', 'Where it is kept', FieldType.text),
      _value('Estimated value'),
      _currency(),
      ..._installments(),
      _ownership(),
      _evidence(),
      const FieldSpec('description', 'Description', FieldType.multiline),
      _succession(),
    ],
  ),
  RecordType(
    kind: Kinds.digitalAsset,
    category: Categories.wealth,
    label: 'Digital asset',
    plural: 'Digital assets & accounts',
    icon: Icons.cloud_outlined,
    subtitleKeys: const ['digitalType', 'provider'],
    description:
        'Record that the asset exists, the provider and what should happen to it. Do not store seed phrases or passwords.',
    fields: [
      const FieldSpec('name', 'Name', FieldType.text, required: true),
      const FieldSpec('digitalType', 'Type', FieldType.choice, options: [
        'Domain name',
        'Website',
        'Online business',
        'Digital IP',
        'Cryptocurrency',
        'Digital wallet',
        'Social media account',
        'Monetised channel',
        'Subscription',
        'Cloud storage',
        'Email account',
      ]),
      const FieldSpec('provider', 'Provider / platform', FieldType.text),
      const FieldSpec('handle', 'Username / handle (no password)', FieldType.text),
      _value('Estimated value'),
      _currency(),
      const FieldSpec('disposition', 'What should happen', FieldType.choice,
          options: ['Transfer', 'Memorialise', 'Close / delete', 'Archive for family', 'Sell']),
      const FieldSpec('accessLocation', 'Where access details are kept (not the secret itself)', FieldType.text),
      _succession(),
    ],
  ),
  RecordType(
    kind: Kinds.liability,
    category: Categories.wealth,
    label: 'Liability',
    plural: 'Liabilities & obligations',
    icon: Icons.receipt_long_outlined,
    subtitleKeys: const ['liabilityType', 'creditor'],
    fields: [
      const FieldSpec('name', 'Name', FieldType.text, required: true),
      const FieldSpec('liabilityType', 'Type', FieldType.choice, options: [
        'Personal loan',
        'Mortgage',
        'Business loan',
        'Credit obligation',
        'Outstanding tax',
        'Guarantee',
        'Other commitment',
      ]),
      const FieldSpec('creditor', 'Creditor', FieldType.text, required: true),
      const FieldSpec('balance', 'Outstanding balance', FieldType.money, required: true),
      _currency(),
      const FieldSpec('terms', 'Payment terms', FieldType.text),
      const FieldSpec('maturityDate', 'Maturity date', FieldType.date),
      const FieldSpec('securedOn', 'Secured on asset', FieldType.ref, refKinds: Kinds.assets),
      _notes(),
    ],
  ),
  const RecordType(
    kind: Kinds.insurance,
    category: Categories.wealth,
    label: 'Insurance policy',
    plural: 'Insurance policies',
    icon: Icons.health_and_safety_outlined,
    subtitleKeys: ['policyType', 'insurer'],
    fields: [
      FieldSpec('name', 'Policy name', FieldType.text, required: true),
      FieldSpec('policyType', 'Type', FieldType.choice,
          options: ['Life', 'Health', 'Property', 'Vehicle', 'Funeral', 'Education', 'Business', 'Other']),
      FieldSpec('insurer', 'Insurer', FieldType.text, required: true),
      FieldSpec('policyNumber', 'Policy number', FieldType.text, sensitive: true),
      FieldSpec('sumAssured', 'Sum assured / cover', FieldType.money),
      FieldSpec('currency', 'Currency', FieldType.choice, options: currencies, defaultValue: 'GHS'),
      FieldSpec('premium', 'Premium', FieldType.text),
      FieldSpec('renewalDate', 'Renewal / expiry date', FieldType.date),
      FieldSpec('policyBeneficiaries', 'Beneficiaries named on the policy', FieldType.multiline,
          hint: 'Policy nominations can take effect outside your will'),
      FieldSpec('agent', 'Agent / contact', FieldType.text),
      FieldSpec('coveredAsset', 'Covers asset', FieldType.ref, refKinds: Kinds.assets),
    ],
  ),

  // ======================= PILLAR 3: MY VAULT =======================
  const RecordType(
    kind: Kinds.document,
    category: Categories.vault,
    label: 'Document',
    plural: 'Documents',
    icon: Icons.description_outlined,
    titleKey: 'title',
    subtitleKeys: ['docCategory', 'expiryDate'],
    hidden: true, // has its own screen with upload/download
    fields: [
      FieldSpec('title', 'Title', FieldType.text, required: true),
      FieldSpec('docCategory', 'Category', FieldType.choice, required: true, options: [
        'Identity',
        'Property',
        'Financial',
        'Business',
        'Insurance',
        'Education & career',
        'Legal & estate',
        'Other',
      ]),
      FieldSpec('issuer', 'Issuing authority', FieldType.text),
      FieldSpec('issueDate', 'Issue date', FieldType.date),
      FieldSpec('expiryDate', 'Expiry date', FieldType.date),
      FieldSpec('relatedRecord', 'Related record', FieldType.ref, refKinds: [
        ...Kinds.assets,
        Kinds.liability,
        Kinds.insurance,
        Kinds.education,
        Kinds.career,
        Kinds.achievement,
        Kinds.willVersion,
      ]),
      FieldSpec('verification', 'Verification status', FieldType.choice,
          options: ['Unverified copy', 'Certified true copy', 'Verified by professional'], defaultValue: 'Unverified copy'),
      FieldSpec('description', 'Description', FieldType.multiline),
    ],
  ),

  // ======================= PILLAR 4: MY LEGACY =======================
  const RecordType(
    kind: Kinds.beneficiary,
    category: Categories.legacy,
    label: 'Beneficiary',
    plural: 'Beneficiaries',
    icon: Icons.volunteer_activism_outlined,
    subtitleKeys: ['relationship'],
    fields: [
      FieldSpec('name', 'Full name', FieldType.text, required: true),
      FieldSpec('relationship', 'Relationship', FieldType.choice, required: true, options: relationships),
      FieldSpec('phone', 'Phone', FieldType.phone),
      FieldSpec('email', 'Email', FieldType.email),
      FieldSpec('address', 'Address', FieldType.multiline),
      FieldSpec('isMinor', 'Is a minor', FieldType.toggle),
      FieldSpec('guardian', 'Guardian / trustee for this beneficiary', FieldType.text),
      _NotesField(),
    ],
  ),
  const RecordType(
    kind: Kinds.allocation,
    category: Categories.legacy,
    label: 'Allocation',
    plural: 'Allocations',
    icon: Icons.pie_chart_outline,
    titleKey: 'assetId',
    hidden: true,
    fields: [
      FieldSpec('assetId', 'Asset', FieldType.ref, required: true, refKinds: Kinds.assets),
      FieldSpec('beneficiaryId', 'Beneficiary', FieldType.ref, required: true, refKinds: [Kinds.beneficiary]),
      FieldSpec('percent', 'Share %', FieldType.percent, required: true),
      FieldSpec('alternateId', 'Alternative beneficiary', FieldType.ref, refKinds: [Kinds.beneficiary]),
      FieldSpec('condition', 'Condition (if any)', FieldType.text, hint: 'e.g. on reaching 25'),
    ],
  ),
  const RecordType(
    kind: Kinds.executor,
    category: Categories.legacy,
    label: 'Executor nomination',
    plural: 'Executors',
    icon: Icons.gavel_outlined,
    subtitleKeys: ['role', 'relationship'],
    description:
        'A nomination records your wish. It does not by itself give anyone legal authority — that comes from a valid will and probate.',
    fields: [
      FieldSpec('name', 'Full name', FieldType.text, required: true),
      FieldSpec('role', 'Role', FieldType.choice, required: true,
          options: ['Primary executor', 'Alternative executor', 'Co-executor', 'Guardian of minor children', 'Trustee']),
      FieldSpec('relationship', 'Relationship', FieldType.choice, options: relationships),
      FieldSpec('phone', 'Phone', FieldType.phone),
      FieldSpec('email', 'Email', FieldType.email),
      FieldSpec('qualifications', 'Professional qualifications', FieldType.text),
      FieldSpec('consented', 'They have agreed to act', FieldType.toggle),
    ],
  ),
  const RecordType(
    kind: Kinds.wish,
    category: Categories.legacy,
    label: 'Personal wish',
    plural: 'Personal wishes',
    icon: Icons.local_florist_outlined,
    titleKey: 'title',
    subtitleKeys: ['type'],
    description: 'Personal wishes guide your family. They are not legally binding will provisions.',
    fields: [
      FieldSpec('type', 'Type', FieldType.choice, required: true, options: [
        'Funeral preferences',
        'Burial or cremation',
        'Memorial instructions',
        'Charitable donation',
        'Family heirloom',
        'Religious or cultural preference',
        'Special request',
      ]),
      FieldSpec('title', 'Title', FieldType.text, required: true),
      FieldSpec('details', 'Details', FieldType.multiline, required: true),
    ],
  ),
  const RecordType(
    kind: Kinds.willVersion,
    category: Categories.legacy,
    label: 'Will draft',
    plural: 'Will drafts',
    icon: Icons.history_edu_outlined,
    titleKey: 'label',
    subtitleKeys: ['status', 'createdOn'],
    hidden: true,
    fields: [
      FieldSpec('label', 'Label', FieldType.text, required: true),
      FieldSpec('status', 'Status', FieldType.choice, options: [
        'Draft',
        'Submitted for legal review',
        'Reviewed by lawyer',
        'Signed and witnessed',
        'Superseded',
      ], defaultValue: 'Draft'),
      FieldSpec('createdOn', 'Created on', FieldType.date),
      FieldSpec('reviewer', 'Reviewing lawyer', FieldType.text),
      FieldSpec('executionDetails', 'Signing & witnessing details', FieldType.multiline,
          hint: 'Date, place, names of the two witnesses'),
      FieldSpec('storedAt', 'Where the signed original is kept', FieldType.text),
      FieldSpec('text', 'Draft text', FieldType.multiline),
    ],
  ),
  const RecordType(
    kind: Kinds.legacyMessage,
    category: Categories.legacy,
    label: 'Legacy message',
    plural: 'Legacy messages & time capsule',
    icon: Icons.mail_outline,
    titleKey: 'title',
    subtitleKeys: ['recipient'],
    description: 'Messages go only to confidants you grant "My Legacy" access, after a verified release. '
        'Choose when each one opens: as soon as access is released, a set time after, or on a specific date.',
    fields: [
      FieldSpec('title', 'Title', FieldType.text, required: true),
      FieldSpec('recipient', 'For', FieldType.text, required: true),
      FieldSpec('message', 'Message', FieldType.multiline, required: true),
      FieldSpec('deliveryMode', 'Deliver', FieldType.choice,
          required: true, options: deliveryModes, defaultValue: deliverOnRelease),
      FieldSpec('delayAmount', 'How long after release', FieldType.number,
          showIf: ('deliveryMode', [deliverAfterDelay]), hint: 'e.g. 6'),
      FieldSpec('delayUnit', 'Unit', FieldType.choice,
          showIf: ('deliveryMode', [deliverAfterDelay]), options: delayUnits, defaultValue: 'Months'),
      FieldSpec('deliverOn', 'Open on', FieldType.date, showIf: ('deliveryMode', [deliverOnDate])),
      FieldSpec('releaseNote', 'Occasion (optional)', FieldType.text, hint: 'e.g. on her wedding day'),
    ],
  ),

  // ======================= PILLAR 5: MY FAMILY =======================
  const RecordType(
    kind: Kinds.familyMember,
    category: Categories.family,
    label: 'Family member',
    plural: 'Family members',
    icon: Icons.people_outline,
    subtitleKeys: ['relationship', 'dateOfBirth'],
    fields: [
      FieldSpec('name', 'Full name', FieldType.text, required: true),
      FieldSpec('relationship', 'Relationship to you', FieldType.choice, required: true, options: relationships),
      FieldSpec('dateOfBirth', 'Date of birth', FieldType.date),
      FieldSpec('deceased', 'Deceased', FieldType.toggle),
      FieldSpec('dependant', 'Financially dependent on you', FieldType.toggle),
      FieldSpec('phone', 'Phone', FieldType.phone),
      FieldSpec('email', 'Email', FieldType.email),
      FieldSpec('clanOrHometown', 'Clan / family house / hometown', FieldType.text),
      FieldSpec('notes', 'Notes', FieldType.multiline),
    ],
  ),
  const RecordType(
    kind: Kinds.familyStory,
    category: Categories.family,
    label: 'Family history entry',
    plural: 'Family history archive',
    icon: Icons.auto_stories_outlined,
    titleKey: 'title',
    subtitleKeys: ['type', 'date'],
    fields: [
      FieldSpec('title', 'Title', FieldType.text, required: true),
      FieldSpec('type', 'Type', FieldType.choice, options: [
        'Family story',
        'Tradition',
        'Ancestral property',
        'Historical record',
        'Milestone',
        'Recorded interview',
      ]),
      FieldSpec('date', 'Date / era', FieldType.date),
      FieldSpec('story', 'Story', FieldType.multiline, required: true),
    ],
  ),

  // ======================= PILLAR 6: MY SUCCESSION =======================
  const RecordType(
    kind: Kinds.confidant,
    category: Categories.succession,
    label: 'Trusted confidant',
    plural: 'Trusted confidants',
    icon: Icons.shield_outlined,
    subtitleKeys: ['relationship', 'email'],
    hidden: true, // managed in Succession screen (links to grants)
    fields: [
      FieldSpec('name', 'Full name', FieldType.text, required: true),
      FieldSpec('relationship', 'Relationship', FieldType.choice, required: true, options: relationships),
      FieldSpec('email', 'Email (their Dossier account)', FieldType.email, required: true),
      FieldSpec('phone', 'Phone', FieldType.phone),
      FieldSpec('responsibilities', 'Responsibilities', FieldType.multiline),
    ],
  ),
  const RecordType(
    kind: Kinds.estateProgress,
    category: Categories.succession,
    label: 'Estate administration progress',
    plural: 'Estate administration',
    icon: Icons.checklist,
    titleKey: 'ownerName',
    hidden: true,
    fields: [],
  ),
];

/// Helper so `const` lists above can include a notes field.
class _NotesField extends FieldSpec {
  const _NotesField() : super('notes', 'Notes', FieldType.multiline);
}
