module MyModule::NFTMarketplace {

    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::vector;

    /// Struct representing an NFT listing in the marketplace
    struct NFTListing has store, key {
        nft_id: u64,           // Unique identifier for the NFT
        price: u64,            // Price in AptosCoin
        seller: address,       // Address of the NFT seller
        is_active: bool,       // Whether the listing is still active
    }

    /// Struct to store all marketplace listings
    struct Marketplace has store, key {
        listings: vector<NFTListing>,
        next_nft_id: u64,
    }

    /// Function to list an NFT for sale in the marketplace
    public fun list_nft(seller: &signer, price: u64) acquires Marketplace {
        let seller_addr = signer::address_of(seller);
        
        // Initialize marketplace if it doesn't exist
        if (!exists<Marketplace>(seller_addr)) {
            let marketplace = Marketplace {
                listings: vector::empty<NFTListing>(),
                next_nft_id: 1,
            };
            move_to(seller, marketplace);
        };

        let marketplace = borrow_global_mut<Marketplace>(seller_addr);
        
        // Create new NFT listing
        let listing = NFTListing {
            nft_id: marketplace.next_nft_id,
            price,
            seller: seller_addr,
            is_active: true,
        };

        // Add listing to marketplace
        vector::push_back(&mut marketplace.listings, listing);
        marketplace.next_nft_id = marketplace.next_nft_id + 1;
    }

    /// Function to purchase an NFT from the marketplace
    public fun buy_nft(buyer: &signer, seller_addr: address, nft_id: u64) acquires Marketplace {
        let marketplace = borrow_global_mut<Marketplace>(seller_addr);
        let listings_len = vector::length(&marketplace.listings);
        
        let i = 0;
        while (i < listings_len) {
            let listing = vector::borrow_mut(&mut marketplace.listings, i);
            
            if (listing.nft_id == nft_id && listing.is_active) {
                // Transfer payment from buyer to seller
                let payment = coin::withdraw<AptosCoin>(buyer, listing.price);
                coin::deposit<AptosCoin>(seller_addr, payment);
                
                // Mark listing as sold
                listing.is_active = false;
                break
            };
            i = i + 1;
        };
    }
}