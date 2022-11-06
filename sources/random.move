

module random::oracle{
    
    use sui::object::{Self,UID};
    use sui::tx_context::{Self,TxContext,sender};
    use sui::transfer;
    use sui::coin::{Self,Coin};
    
    use sui::ecdsa;
    use std::vector;
    
    use sui::sui::SUI;
    struct Random has key{
        id:UID,
        random:vector<u8>,
        lastMaker:address,
        fee:u64,
        owner:address,
    }
  

    
    fun init(ctx:&mut TxContext){
        let vec = vector<u8>[1,3,4,1,2,1,2,3,4];
        let random = ecdsa::keccak256(&vec);
        // let random_number = 0;
        
        // while (vector::length(&random_hash_vec) != 0){
        //     let value = vector::pop_back(&mut random_hash_vec);
        //     random_number = random_number + (value as u64);
        // };
        let random = Random{
            id:object::new(ctx),
            random:random,
            lastMaker:tx_context::sender(ctx),
            fee:100,
            owner:sender(ctx)
        };
        transfer::share_object(random);
    }
  


    public entry fun set_random(r:&mut Random,salt:vector<u8>,ctx:&mut TxContext){
        let new_object = object::new(ctx);
        
        let maker = sender(ctx);
        r.lastMaker = maker;
        let salt_hash = ecdsa::keccak256(&salt);
        let object_hash = ecdsa::keccak256(&object::uid_to_bytes(&new_object));
        let random_number = &mut r.random;
        loop{
            if (vector::is_empty(&salt_hash) && vector::is_empty(&object_hash)){
                break
            };
            
            vector::push_back(random_number,vector::pop_back(&mut object_hash)); 
            vector::push_back(random_number,vector::pop_back(&mut salt_hash)); 
        };
        object::delete(new_object);
        let random_number = ecdsa::keccak256(random_number);
        r.random = random_number;

    }


    fun u64_from_vector(v:&vector<u8>,ctx:&mut TxContext):u64{
        let result = tx_context::epoch(ctx);
        let vec = *v;
        loop{
            if (vector::is_empty(v)){
                break
            };
            result = result + (vector::pop_back(&mut vec) as u64) ;
        };
        result
    }


    public fun get_random_number(random:&Random):vector<u8>{
        random.random
    }
    public fun get_random(random:&Random,token:Coin<SUI>,ctx:&mut TxContext):u64{
        assert!(coin::value(&token) >= random.fee,0);
        transfer::transfer(token,random.owner);
        u64_from_vector(&random.random,ctx)
    }

}