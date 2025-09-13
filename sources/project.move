module MyModule::StakingPool {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Struct representing a user's stake in the pool
    struct UserStake has store, key {
        amount: u64,           // Amount of tokens staked
        stake_time: u64,       // Timestamp when tokens were staked
        total_staked: u64,     // Total tokens staked in the pool
    }

    /// Function to stake tokens into the pool
    public fun stake_tokens(user: &signer, amount: u64) acquires UserStake {
        let user_addr = signer::address_of(user);
        
        // Withdraw tokens from user's account
        let staked_coins = coin::withdraw<AptosCoin>(user, amount);
        
        // Check if user already has a stake
        if (exists<UserStake>(user_addr)) {
            let stake = borrow_global_mut<UserStake>(user_addr);
            stake.amount = stake.amount + amount;
            stake.total_staked = stake.total_staked + amount;
        } else {
            // Create new stake for the user
            let new_stake = UserStake {
                amount,
                stake_time: timestamp::now_seconds(),
                total_staked: amount,
            };
            move_to(user, new_stake);
        };
        
        // Keep the staked coins in the contract (simplified approach)
        coin::deposit<AptosCoin>(user_addr, staked_coins);
    }

    /// Function to unstake tokens from the pool
    public fun unstake_tokens(user: &signer, amount: u64) acquires UserStake {
        let user_addr = signer::address_of(user);
        let stake = borrow_global_mut<UserStake>(user_addr);
        
        // Ensure user has enough staked tokens
        assert!(stake.amount >= amount, 1001);
        
        // Update stake amount
        stake.amount = stake.amount - amount;
        stake.total_staked = stake.total_staked - amount;
        
        // Transfer tokens back to user
        let unstaked_coins = coin::withdraw<AptosCoin>(user, amount);
        coin::deposit<AptosCoin>(user_addr, unstaked_coins);
    }
}