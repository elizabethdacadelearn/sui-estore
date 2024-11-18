#[test_only]
module estore::profile_tests { 
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::coin::{mint_for_testing};
    use sui::sui::{SUI};

    use std::string::{Self};
    use std::debug::print;

    use estore::helpers::init_test_helper;
    use estore::estore::{Self as es, AdminCap, Estore};

    const ADMIN: address = @0xe;
    const TEST_ADDRESS1: address = @0xee;
    const TEST_ADDRESS2: address = @0xbb;
    const TEST_ADDRESS3: address = @0xbc;

    #[test]
    #[expected_failure(abort_code = 0)]
    public fun test() {
        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        // create estore shared object 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let estore1 = string::utf8(b"estore1");

            es::create_estore(estore1, ts::ctx(scenario));
        };

        // place an item to estore shared object. 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let cap = ts::take_from_sender<AdminCap>(scenario);
            let mut store = ts::take_shared<Estore>(scenario);
            let name = string::utf8(b"asset1");
            let description:u64 = 1;
            let price: u64 = 2;

            es::add_item(&cap, &mut store, name, description, price, ts::ctx(scenario));

            ts::return_shared(store);
            ts::return_to_sender(scenario, cap); 
        };

        // Update item_price  
        next_tx(scenario, TEST_ADDRESS1);
        {
            let owner = ts::take_from_sender<AdminCap>(scenario);
            let mut store = ts::take_shared<Estore>(scenario);
            let item_id: u64 = 0;
            let new_price: u64 = 1_000_000_000;
            print(&store);

            es::update_item_price(&owner, &mut store, item_id, new_price, ts::ctx(scenario));

            ts::return_shared(store);
            ts::return_to_sender(scenario, owner); 
        };

        // User1 register with alice 
        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut store = ts::take_shared<Estore>(scenario);
            let nameofuser = string::utf8(b"alice");

            es::register_user(&mut store, nameofuser, ts::ctx(scenario));

            ts::return_shared(store);
        };

        // User2 register with alice again
        next_tx(scenario, TEST_ADDRESS3);
        {
            let mut store = ts::take_shared<Estore>(scenario);
            let nameofuser = string::utf8(b"alice");

            es::register_user(&mut store, nameofuser, ts::ctx(scenario));

            ts::return_shared(store);
        };
        ts::end(scenario_test);
    }

    #[test]
    public fun test_purchase() {
        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        // create estore shared object 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let estore1 = string::utf8(b"estore1");

            es::create_estore(estore1, ts::ctx(scenario));
        };

        // place an item to estore shared object. 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let cap = ts::take_from_sender<AdminCap>(scenario);
            let mut store = ts::take_shared<Estore>(scenario);
            let name = string::utf8(b"asset1");
            let description:u64 = 1;
            let price: u64 = 2;

            es::add_item(&cap, &mut store, name, description, price, ts::ctx(scenario));

            ts::return_shared(store);
            ts::return_to_sender(scenario, cap); 
        };

        // Update item_price  
        next_tx(scenario, TEST_ADDRESS1);
        {
            let owner = ts::take_from_sender<AdminCap>(scenario);
            let mut store = ts::take_shared<Estore>(scenario);
            let item_id: u64 = 0;
            let new_price: u64 = 1_000_000_000;
            print(&store);

            es::update_item_price(&owner, &mut store, item_id, new_price, ts::ctx(scenario));

            ts::return_shared(store);
            ts::return_to_sender(scenario, owner); 
        };

        // User1 register with alice 
        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut store = ts::take_shared<Estore>(scenario);
            let nameofuser = string::utf8(b"alice");

            es::register_user(&mut store, nameofuser, ts::ctx(scenario));

            ts::return_shared(store);
        };

       // User2 buys  the item 
        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut store = ts::take_shared<Estore>(scenario);
            let itemid: u64 = 0;
            let userid: u64 = 1;
            let mut payment = mint_for_testing<SUI>(1_000_000_000, ts::ctx(scenario));

            es::buy_item(&mut store, itemid, userid, &mut payment, ts::ctx(scenario));
            
            transfer::public_transfer(payment, TEST_ADDRESS2);

            ts::return_shared(store);
        };

        ts::end(scenario_test);
    }

    
    #[test]
    public fun test_rent() {
        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        // create estore shared object 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let estore1 = string::utf8(b"estore1");

            es::create_estore(estore1, ts::ctx(scenario));
        };

        // place an item to estore shared object. 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let cap = ts::take_from_sender<AdminCap>(scenario);
            let mut store = ts::take_shared<Estore>(scenario);
            let name = string::utf8(b"asset1");
            let description:u64 = 1;
            let price: u64 = 2;

            es::add_item(&cap, &mut store, name, description, price, ts::ctx(scenario));

            ts::return_shared(store);
            ts::return_to_sender(scenario, cap); 
        };

        // Update item_price  
        next_tx(scenario, TEST_ADDRESS1);
        {
            let owner = ts::take_from_sender<AdminCap>(scenario);
            let mut store = ts::take_shared<Estore>(scenario);
            let item_id: u64 = 0;
            let new_price: u64 = 1_000_000_000;
            print(&store);

            es::update_item_price(&owner, &mut store, item_id, new_price, ts::ctx(scenario));

            ts::return_shared(store);
            ts::return_to_sender(scenario, owner); 
        };

        // User1 register with alice 
        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut store = ts::take_shared<Estore>(scenario);
            let nameofuser = string::utf8(b"alice");

            es::register_user(&mut store, nameofuser, ts::ctx(scenario));

            ts::return_shared(store);
        };

       // User2 rent  the item 
        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut store = ts::take_shared<Estore>(scenario);
            let itemid: u64 = 0;
            let userid: u64 = 1;
            let mut payment = mint_for_testing<SUI>(2_000_000_000, ts::ctx(scenario));

            es::rent_item(&mut store, itemid, userid, &mut payment, ts::ctx(scenario));
            
            transfer::public_transfer(payment, TEST_ADDRESS2);

            ts::return_shared(store);
        };

        ts::end(scenario_test);
    }
}
