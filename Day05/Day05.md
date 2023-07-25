## Breaking Down Tornado Cash

To gain an understanding of the high-level functioning of Tornado Cash, please refer to [Day3](https://github.com/spo0ds/Zero-to-ZKP/blob/main/Day03/Day03.md) in my repository.

![contractView](contractView.png)

To begin, the Tornado Cash contract manages a pool of ETH and also stores deposit commitments. When the contract is instantiated, it creates a Merkle tree accumulator to store all the different deposit commitments made by users. Initially, no deposit commitments exist, so all the deposit commitment values are null. The node for the null value is represented by the hash of 0, denoted as H(0). The Merkle tree accumulator works in such a way that each parent node's value is the hash of its two children nodes. This design enables the creation of a single identifier for the entire database's state, facilitating easy verification of inclusion in the database.

In the future, Tornado Cash will support zero-knowledge proofs (ZKP) of the form "I know a secret password X such that the hash of X is present in the table of all password commitments." This proof of knowledge allows users to prove that they possess a secret value (currently 0, as shown in the picture) and, in the future, it will be X. Along with this knowledge, users also provide all the siblings and the root of the Merkle tree, allowing for efficient log(n) checks to verify that their value is indeed included in the root state of the table. This concept is known as the "Merkle Tree."

The following image illustrates the state of the contract after some users have made deposits and withdrawals.

![depositsWithdrawls](depositsWithdrawls.png)

In this image, three users have made deposits, and one user has made a withdrawal. Each deposit is associated with a password, and the contract can only see the data within the red box. Specifically, the contract has three deposit notes, each representing the hash of the respective deposit passwords. The tree is not yet fully filled, so the fourth value remains the default value, H(0), indicating that no deposit has been made in that slot yet.

Using these values, the Merkle tree accumulator is built, leading to the root that identifies the state of the table.

Now, let's explore what happens when a user wants to make another deposit. They will locally generate password four, hash it to obtain deposit note 4, and then update the tree accordingly, as shown in the image below.

![deposit](deposit.png)

This is the updated state of the contract.

Although the contract is unaware of this, the nullifier for any given withdrawal corresponds to one of the above deposits. For instance, if a user with pw2 wants to make a withdrawal, they know that nullifier 1 is the hash of pw2 but using a different hash function G. This nullifier serves as a unique identifier, preventing a second depositor from withdrawing the same password twice.

![nullifier](nullifier.png)

Let's walk through the process when someone else attempts to withdraw a deposit. Suppose a user with deposit note 3 (dn3) is trying to withdraw their deposit. They would present a ZKP to the contract, proving that they know password 3 such that H(3) is present in the Merkle tree. This proof establishes inclusion in the root and also asserts that G(pw3) matches the public value nullifier 2 that they declare.

![nullifier2](nullifier2.png)

The contract will then verify the ZKP, check if the declared root matches the Tornado Cash tree's root, and ensure that the nullifier value has not been previously declared in the nullifier set. If all checks pass and the nullifier is indeed new, the contract allows the user to withdraw ETH from the smart contract.

![withdrawl](withdrawl.png)

The contract remains unaware of which specific deposit note has been withdrawn, but it does recognize that a password corresponding to a deposit note in the tree has been withdrawn and that this specific password has not been withdrawn before.

**merkleTree.circom**

The MerkleTree checker is used to verify the correctness of a Merkle Proof for a given Merkle root and a leaf value. When we want to prove that a certain number was part of the accumulation process in a cryptographic accumulator (such as a Merkle tree), we typically have to present all the values that were used to generate the root. However, this can become impractical if the dataset is large, resulting in a proof size equal to the full dataset size. Merkle proofs offer a more efficient solution by allowing proofs of inclusion that are logarithmic in size compared to the dataset.

The process of proof verification in a circom circuit involves presenting the leaf value and its sibling, followed by subsequent path elements like uncle, great uncle, and so on, along with their corresponding indices in the path. These indices indicate whether the elements are on the left or right side during the hashing process.

In the circom circuit (merkleTree.circom), we define the input signals for the leaf, root, path elements, and path indices:

```circom
signal input leaf;
signal input root;
signal input pathElements[levels];
signal input pathIndices[levels];
```

Next, we use selectors and hashLeftRight components to handle the case when the leaf is on either the left or right side of its sibling:

```circom
    selectors[i].in[0] <== i == 0 ? leaf : hashers[i - 1].hash;
            selectors[i].in[1] <== pathElements[i];

hashers[i].left <== selectors[i].out[0];
hashers[i].right <== selectors[i].out[1];
```

To determine whether the sibling, uncle, great uncle, etc., are on the left or right side, we use the pathIndices:

```circom
selectors[i].s <== pathIndices[i];
```

We continue this process, plugging in the left sibling into the hashers component, obtaining the parent, and then plugging both the parent and uncle into a hash component, and so on, until we reach the top of the tree.

```circom
selectors[i].in[0] <== i == 0 ? leaf : hashers[i - 1].hash;
        selectors[i].in[1] <== pathElements[i];
        selectors[i].s <== pathIndices[i];

        hashers[i] = HashLeftRight();
        hashers[i].left <== selectors[i].out[0];
        hashers[i].right <== selectors[i].out[1];
```

At the top, we check whether the result is equal to the root. If this check passes, it means that we have a sequence of hash pre-images that lead to the root, starting with the original value we wanted to prove inclusion for.

**withdraw.circom**

In the withdraw.circom circuit, we aim to prove two things. Firstly, we want to demonstrate that we know a secret value that is contained within a Merkle root accumulator. Secondly, we need to prove that this secret value, when hashed using the nullifier hash function, corresponds to a unique identifier (nullifier).

The inputs to the circuit are as follows:

    root: This is the public input, visible to the smart contract, and it represents the ZKP (Zero-Knowledge Proof) that verifies the inclusion of some value in a specific root.
    nullifierHash: This is another public input representing the nullifier hash, and for practical purposes, we can consider it as an implementation of the hash function G.
    recipient, relayer, fee, and refund: These are not involved in the circuit's computations, so we can ignore them for now.
    nullifier: A private input representing the unique identifier (nullifier) that we want to prove knowledge of.
    secret: Another private input representing the deposit password we are withdrawing.
    pathElements and pathIndices: These are auxiliary private inputs that get used in the Merkle tree checker. For now, we don't need to focus on them in the context of the withdrawal; just think of them as values plugged into the Merkle tree checker to ensure the Merkle proof verification.

```circom
signal input root;
signal input nullifierHash;
signal input recipient; // not taking part in any computations
signal input relayer;  // not taking part in any computations
signal input fee;      // not taking part in any computations
signal input refund;   // not taking part in any computations
signal private input nullifier;
signal private input secret;
signal private input pathElements[levels];
signal private input pathIndices[levels];
```

The nullifier hash is computed by using the secret value in the hash function H, which yields the nullifier hash. The circuit then verifies if the nullifier hash matches the public input nullifierHash.To achieve the first objective of proving knowledge of the pre-image (secret) of the nullifier hash, we utilize a commitment hasher component:

```circom
component hasher = CommitmentHasher();
hasher.nullifier <== nullifier;
hasher.secret <== secret;
hasher.nullifierHash === nullifierHash;
```

Next, the circuit checks the inclusion of the leaf (which is the hash of our secret deposit note) in the Merkle root by utilizing the MerkleTreeChecker component.For the second part of the ZKP, we use the Merkle tree checker component:

```circom
component tree = MerkleTreeChecker(levels);
tree.leaf <== hasher.commitment;
tree.root <== root;
    for (var i = 0; i < levels; i++) {
        tree.pathElements[i] <== pathElements[i];
        tree.pathIndices[i] <== pathIndices[i];
    }
```

It is important to note that this circuit preserves privacy. It does not reveal the specific secret value being withdrawn. All the Merkle proof arguments, including the Merkle path, the index of the tree, and other related data, are kept as private inputs. Thus, the circuit proves the knowledge of a valid Merkle path without disclosing the actual secret value. Additionally, the nullifier ensures that the withdrawer's identity remains confidential since it is computed using a different hash function (G) than the one used for the Merkle tree (H). This way, revealing the nullifier does not expose any information about the corresponding deposit.
