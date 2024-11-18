#[test_only]
module estore::profile_tests { 
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::coin::{mint_for_testing};
    use sui::sui::{SUI};

    use std::string::{Self};

    use estore::helpers::init_test_helper;
    use estore::estore::{Self as es, AdminCap, Estore};

    const ADMIN: address = @0xe;
    const TEST_ADDRESS1: address = @0xee;
    const TEST_ADDRESS2: address = @0xbb;

    #[test]
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

        
         
         


        ts::end(scenario_test);
    }





}