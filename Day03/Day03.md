**Building DApps with ZK**

**When can SNARKs be beneficial?**

To address the issue of private state being opaque to smart contracts in Ethereum, SNARKs offer a solution. Instead of directly encrypting and storing private data on the blockchain, properties of the data can be proven using SNARKs. A commitment, such as a hash or encrypted version of the data, is then placed on the blockchain. This approach allows for the verification of non-opaque private state.

SNARKs also enable verifiable computation, which can be advantageous depending on the protocol used. By verifying SNARKs in constant time (O(1)) and shifting the computation to the prover, the expensive nature of replicated computation in Ethereum can be mitigated. Computation on personal computers is significantly faster and cheaper. This approach involves running a computationally intensive algorithm on a computer and sending the result, along with a proof of correctness, to a smart contract. Thus, computation is moved off-chain. While this property is not exclusive to NP (non-polynomial) problems, it allows for the verification of non-polynomial problems in polynomial time. The majority of SNARK development efforts in Ethereum are focused on utilizing verifiable computation for Roll-ups.

**What are the considerations and limitations?**

There are several factors to consider when working with SNARKs:

    Complexity: Implementing SNARKs can be challenging since they only support multiplication and addition, making it difficult to write circuits.

    High fixed gas cost: Verifying SNARKs carries a high fixed gas cost. Regardless of the complexity of the circuit, the verification process incurs significant expenses.

    Interoperability challenges: Contracts can call other contracts, but proving SNARK proofs within a contract would be extremely difficult and costly. To enable contract-to-contract interaction involving SNARK proofs, relayers and off-chain processes need to be employed, introducing additional complexities.

For certain tasks like generating Perlin noise, using Solidity requires less gas compared to verifying a SNARK with three public inputs. However, if multiple layers of Perlin noise are desired, the gas cost increases linearly in EVM (Ethereum Virtual Machine), while SNARK verification remains constant at O(1). This demonstrates the power of O(1) verification, as verifying additional layers in SNARKs becomes cheaper.

Perlin noise finds application in video games and procedural generation.

**Applying SNARKs to an entire blockchain**

This concept forms the basis of ZK Rollups. In ZK Rollups, the verification of an entire state machine within a blockchain is encapsulated within a SNARK. The powerful aspect is that the verifier for this SNARK can be deployed on a decentralized blockchain, allowing for the O(1) verification of correct blockchain execution. Examples of platforms utilizing ZK Rollups are ZK Sync and Starkware, which enable smart contract developers to deploy contracts on an alternate blockchain. This blockchain no longer requires expensive replication across various nodes or incentives such as proof-of-work (PoW) or proof-of-stake (PoS). Instead, a prover off-chain provides proofs of correct blockchain execution, which are then verified on Ethereum. This approach maximizes computational efficiency within a decentralized network.

**Non-Opaque Private State Applications**

    Tornado Cash: Tornado Cash is a well-known mixer application built on blockchain. It allows for private transactions by mixing them together, eliminating the link between deposits and withdrawals. Unlike previous mixers operated by centralized entities, Tornado Cash utilizes ZK proofs through the circom library, making it impossible for the mixing entity (in this case, a contract) to manipulate or retain logs.

    Dark Forest: Dark Forest is a decentralized game that enables obfuscated moves, adding an element of privacy to the gameplay experience.

    ZKML: ZKML enables the proof of performance for machine learning (ML) models without revealing the specific ML model used.

**Tornado Cash: How does it work?**

Tornado Cash functions as a mixer with the following specifications:

    Deposit funds.
    Withdraw funds to a different address.
    Prevent the linkage between the deposit and withdrawal transactions.

To initiate a deposit, a hash of a note (secret state known only to the depositor) is included in an escrow smart contract along with a specified amount of cryptocurrency. The escrow waits until it receives ten hashes, forming a certain-sized anonymity set. Once enough funds have been accumulated, the escrow halts further deposits and enables withdrawals.

To perform a withdrawal, the user needs to prove knowledge of the pre-image of one of the hashes. This proof can be achieved using SNARKs, revealing the pre-image of the hash along with the hash of the note (utilizing a different hash function called hash2).

By storing the second hash in the contract, attempts to withdraw using the same hash can be detected. If a hash has already been used to withdraw, the contract prevents subsequent withdrawals.

While the operation of Tornado Cash involves additional complexities to accommodate deposits and withdrawals at any time, the explanation provided above should suffice to illustrate the basic functionality of Tornado Cash.

![proveHash](proveHash.png)

Suppose an anonymity set of three exists, meaning only three possible withdrawals. Publicly, three hashes are shared since the smart contract requires their verification. These hashes are not randomly chosen but rather valid ones. Privately, the user provides their own hash, and the circuit's outcome yields a nullifier. The note is hashed, and its hash is checked against the three hashes provided during the withdrawal process (line 13). Additionally, the note is hashed again to generate a nullifier.
