import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/assets/asset_service.dart';
import '../../core/sync/models/asset_local.dart';
import '../../core/contracts/contract_service.dart';
import '../../core/contracts/models/contract_model.dart';
import '../../core/auth/auth_service.dart';
import '../../core/theme/app_colors.dart';

class GlobalSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search assets or contracts...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: () => close(context, ''),
    );
  }

  Stream<List<AssetLocal>> _searchAssets(BuildContext context, String q) {
    final uid = context.read<AuthService>().firebaseUser?.uid ?? '';
    if (uid.isEmpty) return Stream.value([]);

    return context.read<AssetService>().getAssetsStream(uid).map((assets) {
      if (q.isEmpty) return assets.take(15).toList();
      return assets.where((a) {
        return a.name.toLowerCase().contains(q.toLowerCase()) ||
            a.category.toLowerCase().contains(q.toLowerCase());
      }).toList();
    });
  }

  Stream<List<ContractModel>> _searchContracts(BuildContext context, String q) {
    final uid = context.read<AuthService>().firebaseUser?.uid ?? '';
    if (uid.isEmpty) return Stream.value([]);

    return context.read<ContractService>().getContractsStream(uid).map((
      contracts,
    ) {
      if (q.isEmpty) return contracts.take(15).toList();
      return contracts.where((c) {
        return c.title.toLowerCase().contains(q.toLowerCase()) ||
            c.vendor.toLowerCase().contains(q.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Assets'),
              Tab(text: 'Contracts'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAssetResults(context, query),
                _buildContractResults(context, query),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetResults(BuildContext context, String q) {
    return StreamBuilder<List<AssetLocal>>(
      stream: _searchAssets(context, q),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final assets = snapshot.data ?? [];
        if (assets.isEmpty) {
          return const Center(child: Text('No matching assets found.'));
        }

        return ListView.builder(
          itemCount: assets.length,
          itemBuilder: (context, index) {
            final asset = assets[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                asset.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(asset.category),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                close(context, asset.name);
                // We're delegating deep linking logic elsewhere for now,
                // but we might want AppRoutes mappings
              },
            );
          },
        );
      },
    );
  }

  Widget _buildContractResults(BuildContext context, String q) {
    return StreamBuilder<List<ContractModel>>(
      stream: _searchContracts(context, q),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final contracts = snapshot.data ?? [];
        if (contracts.isEmpty) {
          return const Center(child: Text('No matching contracts found.'));
        }

        return ListView.builder(
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final contract = contracts[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade50,
                child: const Icon(
                  Icons.description_rounded,
                  size: 20,
                  color: AppColors.secondary,
                ),
              ),
              title: Text(
                contract.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(contract.vendor),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                close(context, contract.title);
              },
            );
          },
        );
      },
    );
  }
}
