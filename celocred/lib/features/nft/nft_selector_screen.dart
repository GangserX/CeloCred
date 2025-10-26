import 'package:flutter/material.dart';

/// NFT Selector Screen for choosing collateral
class NFTSelectorScreen extends StatelessWidget {
  const NFTSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock NFT data
    final nfts = List.generate(
      6,
      (index) => {
        'id': 'NFT-${index + 1}',
        'collection': ['Art Blocks', 'Bored Ape', 'CryptoPunks', 'Azuki', 'Doodles', 'Cool Cats'][index],
        'tokenId': '${1234 + index}',
        'estimatedValue': (500 + index * 100).toDouble(),
        'imageUrl': 'https://via.placeholder.com/150',
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select NFT Collateral'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select an NFT to use as collateral. This will increase your loan limit by 150% of the NFT\'s value.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          
          // NFT Grid
          Expanded(
            child: nfts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No NFTs found in your wallet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: nfts.length,
                    itemBuilder: (context, index) {
                      final nft = nfts[index];
                      return _buildNFTCard(context, nft);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNFTCard(BuildContext context, Map<String, dynamic> nft) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context, nft['id']);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NFT Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  color: Colors.primaries[nft['id'].hashCode % Colors.primaries.length].shade100,
                  child: const Icon(
                    Icons.image,
                    size: 64,
                    color: Colors.black26,
                  ),
                ),
              ),
            ),
            
            // NFT Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nft['collection'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${nft['tokenId']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '\$${nft['estimatedValue']} value',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
