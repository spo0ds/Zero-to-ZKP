## Practical Circuits

**Num2FourBits**

We will implement this circuit using [zkrepl](https://zkrepl.dev/). The purpose of the num2FourBits circuit is to create a gadget that takes an input in the range of 0 to 16 and outputs four signals representing the binary representation of the input.

```circom
pragma circom 2.1.4;

include "circomlib/poseidon.circom";

template num2FourBits () {
    signal input x;

    signal output b0;
    signal output b1;
    signal output b2;
    signal output b3;
}
```

Our objective is to generate witnesses and define a set of constraints that ensure b0, b1, b2, and b3 are valid binary representations of x.

> The precondition is that the input is known to be between 0 and 16. Normally, a range check should be performed to ensure this condition. If the input is not within the range, we do not expect the circuit to work. We will focus only on cases where we assume that there is an oracle guaranteeing that the input X is between 0 and 16.

As a zero-knowledge (ZK) circuit, it may not be particularly interesting to have a specific ZK protocol for a number that can be represented as four bits. However, we are often interested in building circuits using reusable components, and this component, which converts a number into a binary representation, is a crucial reusable part. It can be used for range checks or bit operations on a number, making the num2FourBits circuit highly valuable.

While compiling the circuit alone, we are not primarily concerned with zero-knowledge proofs. However, incorporating ZKP into the circuit is an important primitive that allows us to build non-trivial circuits.

All the signals in the code are field elements, which are residues modulo some prime p. We must be mindful of this throughout the process.

Let's proceed with the constraints section. We need to determine the arithmetic constraints that will guarantee the output is a valid binary representation of the input x. Let's assume b0 represents the least significant bit and b3 represents the most significant bit.

First, we will check that b0 to b3 are either 1 or 0.

```circom
b0 * (b0 - 1) === 0;
b1 * (b1 - 1) === 0;
b2 * (b2 - 1) === 0;
b3 * (b3 - 1) === 0;
```

Next, we will check if the binary representation is equal to the input x.

```circom
1 * b0 + 2 * b1 + 4 * b2 + 8 * b3 === x;
```

We will examine whether these equations are necessary and sufficient. Let's first consider the necessary conditions.

What if we only have the constraint 1 _ b0 + 2 _ b1 + 4 _ b2 + 8 _ b3 === x;?

What would be the failure mode of the circuit?

Since all these variables are residues modulo p, this equation represents a single linear equation with five variables. There are numerous possible values that can satisfy this equation. Therefore, we need to add additional constraints to ensure that each bi is either 0 or 1. Only then can we confirm that the binary representation makes sense.

Now, let's focus on witness generation. We need to specify the proving time, allowing the proving engine to properly fill in the values for b0 to b3 given X. Anyone can fill in these values however they want, but circom provides a convenient utility to programmatically specify how to fill in values derived from the inputs.

```circom
b0 <-- x % 2;
b1 <-- (x - b0) / 2 % 2;
b2 <-- (x - 2 * b1 - b0) / 2 % 2;
b3 <-- (x - 4 * b2 - 2 * b1 - b0) / 2 % 2;
```

Here, I am allowed to use arbitrary operations such as division. This division is effectively a division modulo p, which is equivalent to multiplication by the modular inverse. However, these operations are not allowed when defining constraints. In this case, I am only instructing circom on how to suggest filling in these values to compute the witness. Therefore, I can use any operations that I want.

Now, let's simplify the equations below:

```circom
b0 <-- x % 2;
b1 <-- (x - b0) / 2 % 2;
b2 <-- (x - 2 * b1 - b0) / 2 % 2;
b3 <-- (x - 4 * b2 - 2 * b1 - b0) / 2 % 2;
```

The simplified equations are as follows:

```circom
b0 <-- x % 2;
b1 <-- x \ 2 % 2;
b2 <-- x \ 4 % 2;
b3 <-- x \ 8 % 2;
```

This represents our circuit, and we can test it by plugging in a sample input for x.

```circom
component main { public [ x ] } = num2FourBits();

/* INPUT = {
    "x": "5"
} */
```

To run the circuit in zkrepl, press Shift + Enter.

Output:
b0 = 1
b1 = 0
b2 = 1
b3 = 0

Let's explore an example where a circuit could potentially fail. We will modify the constraint from b0 \* (b0 - 1) === 0; to the following:

```circom
(b0 - 2) * (b0 - 3) === 0;
```

Even though we are still generating a 0101 witness, this altered constraint will lead to failure. The witness we generated will not satisfy the new constraint. Consequently, when using ZKrepl, an "assert failed" error will be encountered.

Now, let's consider the scenario where the witness generation is incorrect. Suppose there was an error in the witness generation phase, and the statement b2 <-- x \ 4 % 2; was mistakenly changed to:

```circom
b2 <-- x \ 2 % 2;
```

As a result, an "assert failed" error will also be triggered. This situation represents a reverse error, where the constraints remain correct, but the witness generation is flawed. Consequently, an improper witness is generated, but the properly set up constraints will ensure that only valid proofs are verified. In this case, we encounter an invalid proof, and circom will indicate that it is unable to generate a valid proof.

Ensuring that the system is properly constrained is of utmost importance, particularly when dealing with circuits designed to secure financial systems. Improper constrainting could potentially lead to the ability to create money out of thin air, which is highly undesirable. Currently, the best practice involves manually examining the circuits and constraints, but this approach may lack confidence and is not entirely reliable. One valuable mental model to keep in mind is to minimize the use of single arrows, whenever possible, in favor of double arrows. Utilizing double arrows helps ensure that each variable being written is uniquely determined by some previously known variables.

To generate constraints for different bits, we can employ the following circom code:

```circom
pragma circom 2.1.4;

include "circomlib/poseidon.circom";

template Num2Bits(nBits) {
    signal input x;

    // If nBits are known during compile time,
    // This will be expanded to b0, b1, b2, and so on...
    signal output b[nBits];

    for (var i = 0; i < nBits; i++)
    {
        b[i] <-- x \ (2 ** i) % 2 ;
    }

    for (var i = 0; i < nBits; i++)
    {
        b[i] * (b[i] - 1) === 0;
    }

    var accum;
    for (var i =0; i < nBits; i++)
    {
        accum += 2 ** i * b[i];
    }
    accum === x;
}

component main { public [ x ] } = Num2Bits(5);

/* INPUT = {
    "x": "5"
} */
```
