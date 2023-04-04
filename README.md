# Ultramarine Smart Contracts

```
$ forge test --gas-report
[⠔] Compiling...
[⠒] Compiling 38 files with 0.8.17
[⠃] Solc 0.8.17 finished in 3.14s
Compiler run successful

Running 1 test for test/FactoryUltramarine.t.sol:FactoryUltramarineTest
[PASS] testCreateGame() (gas: 3180216)
Test result: ok. 1 passed; 0 failed; finished in 6.25ms
```

| src/FactoryUltramarine.sol:FactoryUltramarine contract |                 |         |         |         |         |
| ------------------------------------------------------ | --------------- | ------- | ------- | ------- | ------- |
| Deployment Cost                                        | Deployment Size |         |         |         |         |
| 3715788                                                | 18590           |         |         |         |         |
| Function Name                                          | min             | avg     | median  | max     | # calls |
| createGame                                             | 3149474         | 3149474 | 3149474 | 3149474 | 1       |
| getGame                                                | 19759           | 19759   | 19759   | 19759   | 1       |

| src/Ultramarine.sol:Ultramarine contract |                 |       |        |       |         |
| ---------------------------------------- | --------------- | ----- | ------ | ----- | ------- |
| Deployment Cost                          | Deployment Size |       |        |       |         |
| 3049439                                  | 16443           |       |        |       |         |
| Function Name                            | min             | avg   | median | max   | # calls |
| getButtons                               | 5420            | 5420  | 5420   | 5420  | 1       |
| getGame                                  | 13562           | 13562 | 13562  | 13562 | 1       |
