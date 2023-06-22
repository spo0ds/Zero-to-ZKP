**Circom Vs. Zokrates**

Circom allows us to write ZK circuits and provides a level of specificity in expressing the proving equations that are equivalent to the function.

On the other hand, Zokrates requires us to write a program that it compiles into a set of constraints. While this approach may offer a better developer experience in some aspects, it limits the flexibility to optimize these constraints manually. In certain situations, such as when operating within resource-constrained environments, having fine-grained control over writing out the equations ourselves becomes crucial.

If we consider various programming stacks, including circuit programming stacks where we write the constraint systems ourselves or higher-level frameworks, circom is presently the only viable stack. Other projects are still in the research and development stage. Therefore, if our goal is to build an end-to-end ZK application that enables users to generate ZK-Snark proofs in a browser, circom and snarkJS provide the most feasible tool stack to achieve this.

**Circuits**

Before we delve into circom, let's establish a conceptual framework for our circuits. We will consider a specific function and thoroughly analyze what ZK-Snarks is proving.

The function takes four inputs: x1, x2, x3, and x4. The computation of these inputs results in the output (Out): (x1 + x2) \* x3 - x4.

ZK-Snarks asserts that I possess certain secrets (x1, x2, x3, and x4) such that the computed result satisfies the equation. ZK-Snarks allows a 200-byte signature that confirms my knowledge of the input tuple without explicitly revealing its contents.

**What is happening in this scenario?**

When we evaluate the function internally, we compute various intermediate values. First, we sum x1 and x2, storing the result in the intermediate variable y1. Next, we calculate y2 as the product of x3 and the intermediate value y1. Finally, the output is obtained by subtracting x4 from y2.

This sequence of computations represents the trace of the computation.

Snarks takes a provided computational trace (x1, x2, x3, x4, y1, y2, Out) and proves that specific constraints are satisfied. From the snark prover's perspective, the inputs, outputs, and intermediate values are all considered inputs to the proving process, collectively referred to as the witness. Snarks will generate a valid proof if the following three constraints are met:

- y1 == x1 + x2
- y2 == y1 \* x3
- y2 == Out + x4

The reason the third constraint is expressed using addition is because, with snarks, the constraints that can be proven to have satisfying assignments follow the form of "a = b + c" or "a = b \* c."

The output (Out) is publicly known, while the inputs are kept secret, ensuring that the three equations hold for the tuple of seven numbers.

In the case of division, the constraints we write will not align one-to-one with the computation steps, as shown in the previous example. Instead of using multiplication in the function, we have a division operator.

(Out): (x1 + x2) / x3 - x4

To convince someone that a satisfying assignment exists for a set of equations, I would like to provide them with the following equations:

- y1 = x1 + x2
- y2 = y1 / x3
- Out = y2 - x4

Therefore, the prover equations will be:

- y1 == x1 + x2
- y1 == y2 \* x3
- y2 == Out + x4

By examining this set of equations, you can be reasonably confident that I possess x1, x2, x3, x4, y1, and y2. If these equations are satisfied, you can conclude that I have an input to the aforementioned function that produces the desired output (Out).

**Circom**

Circom enables us to write ZK circuits. It provides a language for expressing sequences of equations like the ones mentioned earlier and subsequently transforms them into ZK-Snark protocols. ZK-Snark is a tool that takes these equations and constructs a protocol to prove the knowledge of secret values that satisfy the equations.

There are two versions of circom available. The actively maintained version is circom 2.0, written in Rust. However, we will utilize the older circom 1.0, which has a slightly different syntax. The older version of circom was designed to be compatible and user-friendly with JavaScript runtimes.

**Snark JS**

Snark JS is a JavaScript library designed for working with the outputs of circom. It allows us to generate ZK proofs in a browser or verify ZK proofs on a node web server using a file containing all the parameters of a ZK protocol for a specific function. Additionally, Snark JS provides utilities to generate a solidity verifier for ZK-Snark proofs and various other helpful functionalities.

**Useful Tools**

We will explore several tools developed within the circom ecosystem. Specifically, we are working with a project that utilizes "Hardhat-circom," a set of automations integrated with the Hardhat development ecosystem. This plugin for Hardhat streamlines the process of building ZK circuits.

Another valuable tool is ZKREPL, an online playground for building and compiling circuits. It offers a fast and iterative environment for working with ZK circuits.

Circomlib is a library of useful circuits maintained by iden, the maintainers of circom.

**Overview of ZK Dapp**

Circom transforms sets of constraints into ZK protocols. The Circom Compiler implements the meta protocol, which takes the code of a function f and produces a ZK protocol for that function. A ZK protocol consists of a pair of keys: a proving key and a verifying key. The proving key allows anyone who knows the witness to generate a proof, outlining the steps required to obtain the 200-byte signature of the computation. The verifying key enables anyone to verify the validity of a proof.

![zkDapp](ZKDapp.png)

Typically, the proving keys are distributed to clients, such as the dark forest clients in this example. The game itself needs to download a proving key and have access to snarkJS for generating proofs. Users specify the inputs.

The verifying key usually resides in the backend of an application. For instance, in a web app, the verifying key is stored on the backend server and used to verify the validity of signatures when users make posts with ZK proofs.

**Getting Familiar with Circom**

To get started, visit the [circom-starter](https://github.com/0xPARC/circom-starter) repository, which provides three circuits named "division," "hash," and "simple polynomials." Clone the repository and install it using the yarn command.

This repository uses circom 1, which depends on hardhat circom.

Let's begin by examining the polynomial circuits. The following circuit example is similar in complexity to the one discussed earlier:

```circom
pragma circom 2.0.3;

template Main() {
  signal input x;
  signal x_squared;
  signal x_cubed;
  signal output out;

  x_squared <-- x * x;
  x_cubed <-- x_squared * x;
  out <-- x_cubed - x + 7;

  x_squared === x * x;
  x_cubed === x_squared * x;
  out === x_cubed - x + 7;
}

component main = Main();
```

This circuit computes a simple polynomial on a single input value, denoted as x. The polynomial is x^3 - x + 7. The circuit includes variables x_squared, x_cubed, and out. In terms of constraint equations, the circuit aims to prove that we possess four values (x, x_squared, x_cubed, and out) that satisfy a set of equations. Knowing the satisfying assignment to these equations is equivalent to having knowledge of an x value that belongs to the computation of the polynomial.

The code for the prover, as discussed in the previous example, is as follows:

```circom
x_squared === x * x;
x_cubed === x_squared * x;
out === x_cubed - x + 7;
```

Circom allows writing quadratic constraints using the === operator, as quadratic expressions can be broken down into addition and multiplication operations.

All the variables involved in the statement being proven are called "signals." The three keywords used for variables are private, input, and output. In the previous example, we were proving a set of equations for seven values, where one value was known and six were unknown.

We aim to prove x such that f(x) = y. Often, it is desirable for x to be private, while y is not.

At the constraint level, all four variables in the code are treated the same way, and the distinction between inputs, intermediate values, and outputs is mainly semantic. When performing computations, it is useful to consider some values as inputs, some as intermediate values in the computation traces, and some as outputs.

The following lines of code are equivalent:

```circom
x_squared <-- x * x;
x_cubed <-- x_squared * x;
out <-- x_cubed - x + 7;

x_squared === x * x;
x_cubed === x_squared * x;
out === x_cubed - x + 7;
```

So, what is the difference?

In an older version of snarkJS and circom, users were required to provide x1, x2, x3, x4, y1, y2, and out. The user was responsible for generating all the intermediate values, and circom would only compile a protocol for proving that the seven values satisfy the equations.

However, it is more convenient to think of these values as functions, where some computation is performed on certain inputs. It is especially useful when dealing with intermediate values since computing them manually outside of circom and then plugging them in can be cumbersome.

In practice, circom allows specifying that some values are derived values that can be deterministically computed from other values. The set of derived values includes intermediate signals (intermediate values) and outputs, while the set of base values consists of inputs. This feature saves time and effort by automatically setting the values of x_squared, x_cubed, and out within the circuit.

Essentially, circom serves two functions: defining a set of constraints that are equivalent to a specific function and allowing the definition of how to fill in all the nodes on the computation graph at proving time to satisfy the constraints.

The code snippet below specifies the witness generation for generating a Zero-Knowledge proof that you know a secret x resulting in a public out:

```circom
x_squared <-- x * x;
x_cubed <-- x_squared * x;
out <-- x_cubed - x + 7;
```

In this code, constraints are represented using ===, while witness generation is represented using <--.

Now, let's compile the circuits by running the following command:

> yarn circom:dev --circuit simple-polynomial

This will generate four new files along with artifacts, which we will explore later. Let's discuss the purpose of these files:

simple-polynomial.r1cs: This file represents the low-level representation of all the constraints. It serves as an intermediate representation that can be used across different stacks implementing the groth 16 protocol.

simple-polynomial.wasm: This file is a WebAssembly (wasm) executable program that implements the circuit's computation, as described by the following code:

```circom
x_squared <-- x * x;
x_cubed <-- x_squared * x;
out <-- x_cubed - x + 7;
```

simple-polynomial.vkey.json: This file contains the verification key, which is a constant-sized bit representation.

simple-polynomial.zkey: This file contains the proving key.

The verification key (simple-polynomial.vkey.json) is used in a Node.js backend or a smart contract to verify ZK proofs on-chain. On the other hand, the proving key (simple-polynomial.zkey) is used in clients such as browser web apps or desktop apps.

Additionally, a Solidity file is generated, which converts the verification key into code. It includes a verifyProof function that can be called by other smart contracts to verify the proofs generated using the simple-polynomial.zkey file.

The flow of constraints and witness generation is almost identical. Circom provides syntactic sugar when the two are equivalent, allowing us to save lines of code. The syntax is as follows:

```circom
x_squared <== x * x;
x_cubed <== x_squared * x;
out <== x_cubed - x + 7;
```

If the constraints and witness generation are not equivalent, a malicious prover could generate a valid proof with a degree of freedom, even without knowledge of x. The double arrow (<==) ensures consistency between the witness and the constraints.

Now, let's examine the division code:

```circom
pragma circom 2.0.3;

template Main() {
  signal input x1;
  signal input x2;
  signal input x3;
  signal input x4;

  signal y1;
  signal y2;

  signal output out;

  y1 <-- x1 + x2;
  y2 <-- y1 / x3;
  out <-- y2 - x4;

  y1 === x1 + x2;
  y1 === y2 * x3;
  out === y2 - x4;
}

component main { public [ x2 ] } = Main();
```

This circuit computes the same equation discussed in the previous example. Witness generation follows a straightforward process.

The use of division is the main reason for employing the single arrow (<--) notation. It allows for more complex functions that cannot easily be broken down into multiplication and addition, and then constrained later.

The code can be further simplified as:

```circom
y1 <== x1 + x2;
y2 <-- y1 / x3;
y1 === y2 * x3;
out <== y2 - x4;
```

Now, let's move on to the hash code:

```circom
pragma circom 2.0.3;

include "../node_modules/circomlib/circuits/mimcsponge.circom";

template Main() {
  signal input x;

  signal output out;

  component mimc = MiMCSponge(1, 220, 1);
  mimc.ins[0] <== x;
  mimc.k <== 0;

  out <== mimc.outs[0];
}

component main = Main();
```

When building larger circuits, it is advantageous to use reusable code snippets. For this purpose, circom provides templates. In this example, we import a circuit for a friendly hash function:

```circom
template MiMCSponge(nInputs, nRounds, nOutputs) {}
```

The file for this template is located at node_modules/circomlib/circuits/. The template takes an array of nInputs, nRounds, and nOutputs, which we define in our hash code:

```circom
component mimc = MiMCSponge(1, 220, 1);
```

We then feed a value into mimc.ins[0], where the generation-time value of ins[0] in the mimc component is set equal to x. Additionally, at constraints time, mimc.ins[0] is constrained to be equal to x. The same applies to the value of k. Finally, we feed and constrain the output of the mimc component into the out variable.

Now, let's explore what proofs and inputs look like.

Returning to the simple polynomial circuit, we can see that we have defined one input and one output. During the compilation process, the necessary files for defining the ZK standard protocol are generated. If we, as consumers of the protocol, want to generate or verify proofs, what does it actually look like?

Hardhat circom includes a smoke test that generates a witness for a sample input. It then generates a proof for that witness and verifies it. You can specify the input in simple-polynomial.json using a straightforward JSON format. For each named input, you assign a numerical value, which should be enclosed in quotation marks to interpret it as a string:

```json
{
  "x": "5"
}
```

Hardhat circom generates a witness file (simple-polynomial.wtns) in the artifacts directory for the provided input. It then generates a proof (simple-polynomial.proof.json), which, in the case of groth16, consists of a trio of elliptic curve points. Additionally, it generates a simple-polynomial.public.json file containing all the public signals. The verification key (simple-polynomial.vkey.json) and the proof are verified using this public input.

Regardless of the size of your computation, the verification key and ZK-Snarks proof are always constant in size, around 200 bytes. The size of the proving key depends on the size of the computation and the number of inputs. It typically ranges from tens of kilobytes to several megabytes.
