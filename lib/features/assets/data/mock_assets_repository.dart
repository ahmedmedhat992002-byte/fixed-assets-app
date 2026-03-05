import '../domain/entities/asset_entities.dart';

class MockAssetsRepository {
  const MockAssetsRepository();

  List<AssetItem> fetchRecentlyAdded() {
    return const [
      AssetItem(
        name: 'Conveyor belt',
        category: 'Machinery',
        valuedAt: 'LE 650,000',
        date: '15-02-2023',
        status: 'Active',
      ),
      AssetItem(
        name: 'Company van',
        category: 'Vehicles',
        valuedAt: 'LE 650,000',
        date: '15-02-2023',
        status: 'Active',
      ),
      AssetItem(
        name: 'Apparel warehouse',
        category: 'Fixed assets',
        valuedAt: 'LE 1,500,000',
        date: '05-02-2023',
        status: 'Active',
      ),
    ];
  }

  List<TransactionItem> fetchLatestTransactions() {
    return const [
      TransactionItem(
        title: 'Bitcoin returns',
        amount: '+LE 250,000',
        date: 'Received on 10/01/2023',
        isGain: true,
      ),
      TransactionItem(
        title: 'Forex investment',
        amount: '+LE 50,000',
        date: '10/01/2023',
        isGain: true,
      ),
    ];
  }
}
