
/// Module: estore
module estore::estore {
use std::string::{String};
use sui::coin::{Coin,split, put,take};
use sui::balance::{Balance,zero};
use sui::sui::SUI;
use sui::event;

//define errors
const ONLYOWNER:u64=0;
const ITEMEDOESNOTEXISTS:u64=1;
const MUSTBEREGISTERED:u64=2;
const INSUFFICIENTBALANCE:u64=3;
const ITEMALREADYSOLD:u64=4;
const ITEMALREADYRENTED:u64=5;
const ALREADYREFUNDED:u64=6;
//define user data types

public struct Estore has store,key{
    id:UID,
    name:String,
    storeid:ID,
    balance:Balance<SUI>,
    items:vector<Item>,
    rented:vector<Renteditem>,
    refunds:vector<RefundRequest>,
    registeredusers:vector<User>,
    boughtitems:vector<BoughtItems>
}
public struct Renteditem has store{
    id:u64,
    itemid:u64,
    userid:u64,
    refunded:bool
}
public struct BoughtItems has store{
    id:u64,
    itemid:u64,
    userid:u64
}
public struct RefundRequest has store{
    id:u64,
    userid:u64,
    itemid:u64,
    resolved:bool,
    buyersaddress:address
}
public struct Item has store,drop{
    id:u64,
    nameofitem:String,
    description:u64,
    price:u64,
    sold:bool,
    rented:bool,
    complain:bool
}
public struct User has store{
    id:u64,
    nameofuser:String
}
//define admin capabailitiess
public struct AdminCap has key{
    id:UID,
    estoreid:ID
}
//define events

public struct EstoreCreated has copy,drop{
    name:String,
    id:ID
}

public struct ItemAdded has copy,drop{
    name:String,
    id:u64
}
public struct PriceUpdated has copy,drop{
    name:String,
    newprice:u64
}
public struct UserRegistered  has copy,drop{
    name:String,
    id:u64
}
public struct Paid  has copy,drop{
    name:String,
    id:u64
}
public struct RentedItem has copy,drop{
    name:String,
    by:u64
}
//define functions
public entry fun create_estore(name:String,ctx:&mut TxContext){

    let id=object::new(ctx);
    let storeid=object::uid_to_inner(&id);

    let newstore=Estore{
        id,
        name,
        storeid:storeid,
        balance:zero<SUI>(),
        items:vector::empty(),
        rented:vector::empty(),
        refunds:vector::empty(),
        registeredusers:vector::empty(),
        boughtitems:vector::empty()
    };

     transfer::transfer(AdminCap {
        id: object::new(ctx),
        estoreid: storeid,
    }, tx_context::sender(ctx));

     event::emit(EstoreCreated{
        name,
        id:storeid
    });

transfer::share_object(newstore);
}

//add items to the store
public entry fun add_item(owner:&AdminCap, store:&mut Estore,nameofitem:String,description:u64,price:u64,ctx:&mut TxContext){

    //verify that its only the admin performing the action
    assert!(&owner.estoreid == object::uid_as_inner(&store.id),ONLYOWNER);
    let id:u64=store.items.length();
    //create a new item
    let newitem=Item{
        id,
        nameofitem,
        description,
        price,
        sold:false,
        rented:false,
        complain:false
    };

    store.items.push_back(newitem);

     event::emit(ItemAdded{
        name:nameofitem,
        id
    });
    
}

//update item price

public entry fun update_item_price(owner:&AdminCap, store:&mut Estore,itemid:u64,newprice:u64,ctx:&mut TxContext){

    //verify that its the owner performing the action
     assert!(&owner.estoreid == object::uid_as_inner(&store.id),ONLYOWNER);

     //verify that item actually exists
     assert!(itemid<=store.items.length(),ITEMEDOESNOTEXISTS);

     store.items[itemid].price=newprice;


     event::emit(PriceUpdated{
        name:store.items[itemid].nameofitem,
        newprice
    });
}

//user regiter or login to estore

public entry fun register_user(store:&mut Estore, nameofuser:String, ctx:&mut TxContext){

    //verify that username is unique
    let mut startindex:u64=0;
    let totaluserslength=store.registeredusers.length();

    while(startindex < totaluserslength){
        let user=&store.registeredusers[startindex];

        if(user.nameofuser==nameofuser){
            abort 0
        };

        startindex=startindex+1;
    };

    //register new users
    let newuser=User{
        id:totaluserslength,
        nameofuser,
    };
    store.registeredusers.push_back(newuser);

    
     event::emit(UserRegistered{
        name:nameofuser,
        id:totaluserslength
    });
}


//buy item

public entry fun buy_item(store:&mut Estore,itemid:u64,userid:u64,payment:&mut Coin<SUI>,ctx:&mut TxContext){
    //verify that item actually exists 
    assert!(itemid<=store.items.length(),ITEMEDOESNOTEXISTS);

    //verify that user is already registered
    assert!(userid<=store.registeredusers.length(),MUSTBEREGISTERED);

    //verify the amount is greater than the price
    assert!(payment.value() >= store.items[itemid].price,INSUFFICIENTBALANCE);

    //verify that item is not sold

    assert!(store.items[itemid].sold==false,ITEMALREADYSOLD);

    //verify that item is not rented
    assert!(store.items[itemid].rented==false,ITEMALREADYRENTED);

    //purchase the item
    let payitem=payment.split(store.items[itemid].price,ctx);

    put(&mut store.balance,payitem);
    let id:u64=store.boughtitems.length();

    let boughtitem=BoughtItems{
        id,
        itemid,
        userid
    };
    //update items status to sold
    store.items[itemid].sold=true;
    store.boughtitems.push_back(boughtitem);
    event::emit(Paid{
        name:store.items[itemid].nameofitem,
        id
    });
}

//rent an item

public entry fun rent_item(store:&mut Estore,itemid:u64,userid:u64,payment:&mut Coin<SUI>,ctx:&mut TxContext){
    //verify that item actually exists 
    assert!(itemid<=store.items.length(),ITEMEDOESNOTEXISTS);

    //verify that user is already registered
    assert!(userid<=store.registeredusers.length(),MUSTBEREGISTERED);

    //verify the amount is greater than the price
    assert!(payment.value() >= (store.items[itemid].price*2),INSUFFICIENTBALANCE);

    //verify that item is not sold

    assert!(store.items[itemid].sold==false,ITEMALREADYSOLD);

    //verify that item is not rented
    assert!(store.items[itemid].rented==false,ITEMALREADYRENTED);

    //purchase the item
    let payitem=payment.split(store.items[itemid].price,ctx);

    put(&mut store.balance,payitem);
    let id:u64=store.boughtitems.length();

    let renteditem=Renteditem{
        id,
        itemid,
        userid,
        refunded:false
    };
    store.rented.push_back(renteditem);
    //update items status
    store.items[itemid].rented==true;
    event::emit(RentedItem{
        name:store.items[itemid].nameofitem,
        by:userid
    });
}

//return rented item
public entry fun return_rented_item(store:&mut Estore,userid:u64,itemid:u64,buyersaddress:address,ctx:&mut TxContext){
    //verify that items is rented

    let mut index:u64=0;
    let totalrenteditems=store.rented.length();

    while(index < totalrenteditems){
        let item=&store.rented[index];
        if(item.itemid==itemid && item.userid==userid){
            //request refund of deposits
            let id=store.refunds.length();
            let newrefundrequest=RefundRequest{
                 id,
                 userid,
                 itemid,
                 resolved:false,
                 buyersaddress
            };
            store.refunds.push_back(newrefundrequest);
        };
        index=index+1;
    }
}

//admin approves refun request of the deposit

public entry fun deposit_refund(store:&mut Estore,refundid:u64,amount:u64,owner:&AdminCap,ctx:&mut TxContext){

    //verify ist the admin performing the action
    assert!(&owner.estoreid == object::uid_as_inner(&store.id),ONLYOWNER);
    //verify that the refund is not resolved
    assert!(store.refunds[refundid].resolved==false,ALREADYREFUNDED);
    //verify the store has sufficient balance to perform the refund
    let itemid=&store.refunds[refundid].itemid;

     let refundamount = take(&mut store.balance, amount, ctx);
     transfer::public_transfer(refundamount, store.refunds[refundid].buyersaddress);  
       

    store.refunds[refundid].resolved=true;
}

//owner witdraa all amounts
 public entry fun withdraw_funds(
        store: &mut Estore,   
        owner: &AdminCap,
        amount:u64,
        recipient:address,
         ctx: &mut TxContext,
    ) {

        //verify amount
          assert!(amount > 0 && amount <= store.balance.value(), INSUFFICIENTBALANCE);
          //verify ist the admin performing the action
          assert!(&owner.estoreid == object::uid_as_inner(&store.id),ONLYOWNER);
        let takeamount = take(&mut store.balance, amount, ctx);  
        transfer::public_transfer(takeamount, recipient);
       
    }
}

