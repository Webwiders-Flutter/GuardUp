import '../enum/transaction_type.enum.dart';
import '../model/bank_account.model.dart';
import '../enum/discount_type.enum.dart';
import '../model/plan.model.dart';
import '../model/transaction.model.dart';

/// Placeholder bank accounts for withdrawal sheet previews.
const List<BankAccount> bankAccountPlaceholders = [
  BankAccount(
    id: '1',
    accountNumber: '1234567890129875',
    accountHolder: 'Rock Smith',
    bankName: 'Bank Name',
    branch: 'indore',
    ifscCode: 'WORD6589',
    branchAddress: 'indore',
  ),
];

/// Prototype membership plans matching production defaults.
final List<PlanModel> membershipPlanPlaceholders = [
  const PlanModel(
    id: '59caafd7-f530-4bf2-b53d-929601f37962',
    name: 'Silver Shield',
    description: [
      '10% off every booking, up to ₹500 per booking',
      'Access to all verified bodyguards',
      'Standard customer support',
    ],
    pricePerMonth: 499.00,
    discount: 10.00,
    discountType: DiscountType.percentage,
    discountUpto: 500.00,
    isPopular: false,
    displayOrder: 1000,
  ),
  const PlanModel(
    id: '8e85404f-763e-458b-ab18-03502ec85d60',
    name: 'Gold Sentinel',
    description: [
      '20% off every booking, up to ₹1,500 per booking',
      'Access to all verified bodyguards and security companies',
      'Priority customer support',
      'Priority matching for urgent bookings',
    ],
    pricePerMonth: 999.00,
    discount: 20.00,
    discountType: DiscountType.percentage,
    discountUpto: 1500.00,
    isPopular: true,
    badge: '★ MOST POPULAR',
    displayOrder: 2000,
  ),
  const PlanModel(
    id: '2dcb905e-0882-4f2c-9051-c8a483532147',
    name: 'Platinum Elite',
    description: [
      '30% off every booking, no upper limit',
      'Access to all verified bodyguards and security companies',
      'Dedicated 24/7 support line',
      'Priority matching for urgent bookings',
      'Free cancellation up to 2 hours before a booking',
    ],
    pricePerMonth: 1999.00,
    discount: 30.00,
    discountType: DiscountType.percentage,
    isPopular: false,
    displayOrder: 3000,
  ),
];

/// Prototype transactions for wallet screen.
final List<TransactionModel> transactionFixtures = [
  TransactionModel(
    id: 'tx_1',
    amount: 250.0,
    currency: 'USD',
    type: TransactionType.credit,
    title: 'Received from booking ID #f23234',
    bookingId: '#f23234',
    dateTime: DateTime(2026, 3, 23, 18, 36),
    formattedDate: '23 March 2026, 06:36pm',
  ),
  TransactionModel(
    id: 'tx_2',
    amount: 250.0,
    currency: 'USD',
    type: TransactionType.debit,
    title: 'Bank Withdraw',
    dateTime: DateTime(2026, 3, 23, 18, 36),
    formattedDate: '23 March 2026, 06:36pm',
  ),
  TransactionModel(
    id: 'tx_3',
    amount: 250.0,
    currency: 'USD',
    type: TransactionType.credit,
    title: 'Received from booking ID #f23234',
    bookingId: '#f23234',
    dateTime: DateTime(2026, 3, 23, 18, 36),
    formattedDate: '23 March 2026, 06:36pm',
  ),
];
