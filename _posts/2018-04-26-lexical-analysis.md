---
layout: post
title: Chapter 2 - Lexical Analysis
author: Tesla Lee
date: 2018-04-26 00:00:00 +0800
categories: Compiler
---
『Modern Compiler Implementation in C』词法分析部分笔记和总结。

<!--more-->

## 前言

> **lex-i-cal** : of or relating to words or the vocabulary of a language as distinguished from its grammar and construction
>
> --- Webster's Dictionary

要将程序从一种语言翻译到另一种语言，编译器要先将程序处理成**片段**，并理解其**结构**和**意义**，然后将片段重新再组合。编译器前端负责**分析**，而后端负责**整合**。

分析工作主要:

* 词法分析（Lexical analysis）：将输入识别成词素，既（Lexical Token）
* 语法分析（Syntax analysis）：分析程序的结构
* 语义分析（Semantic analysis）：计算出程序的意义

词法分析器输入字符流，输出词，关键字，符号等。

## LEXICAL TOKENS（词素）
Lexical token 是一个字符序列，它是一门语言的最小语法元素。一门编程语言的 token 类型，是一个有限集合。

### 例如：

Token 类型 例子
* `ID` foo n14, last
* `NUM` 74 0 00 082
* `REAL` 66.1 .5 10. 1e66 5.5e-10
* `IF` if
* `COMMA` ,
* `NOTEQ` !=
* `LPAREN` (
* `RPAREN` )

像 if，void，这样的符号，我们称之为**保留字**，在大部分语言里，保留字不能作为 ID 来使用。除了上面这些 Token 以外，字符流中还有非 token 内容。例如：

* 注释  /* try again */
* 预处理 #include <stdio.h>
* 预处理 #define NUMS 5 , 6
* 宏 NUMS
* 空格，换行，缩进等

弱语言需要有一个宏预处理器，宏预处理去先操作输入流，进行预处理，生成新的字符流输出给词法分析器。当然，也可以直接将宏预处理器集成到词法分析器中去。

比如有这样一段代码：

```c
/* find a zero */
float match0(char *s)
{
  if (!strncmp(s, "0.0", 3))
  return 0.;
}
```
词法分析器在输入这段代码后，会输出：
`FLOAT` `ID(match0)` `LPAREN` `CHAR` `STAR` `ID(s)` `RPAREN` `LBRACE` `IF` `LPAREN` `BAND` `ID(strncmp)` `LPAREN` `ID(s)` `COMMA` `STRING(0.0)` `COMMA` `NUM(3)` `RPAREN` `RPAREN` `RETURN` `REAL(0.0)` `SEMI` `RBRACE` `EOF`

从上面的输出我们可以看到，每一个输出的 Token 都有类型。其中，像 `ID` 或 `STRING` 等会带有值来提供额外的信息。

那么，接下来的问题是，我们用什么来描述 Token 的规则？用什么语言来实现词法分析器？我们完全可以使用自然语言来直接描述规则，比如下面这样的：

> `标识符（ID）`是由字母和数字组成的字符序列，首个字符必须是字母开头。同时 `_` 下划线也认为是字母。

同时,我们也可以使用任意合适的语言去实现词法分析器。不过，在这里，我们会使用**正则表达式**来描述词法规则，用**确定性有限自动机**来实现，同时，还会使用**数学语言**来将这两者联系起来。

## REGULAR EXPRESSION（正则表达式）
一门语言，是一个字符串的集合；字符串是符号的有限序列；符号来自一个优先符号集合。我们这样描述一门语言时，并没有赋予字符串以任何意义，我们只是去区分字符串是否属于这门语言。为了能够仅仅使用有限的规则来描述一门语言，我们使用**正则表达式**来标记这些规则。每一条**正则表达式**表示一组字符串。

下面是正则表达式的基本规则：
- **Symbol（符号）**：对于每一个符号 **a** ，直接表示字符串 **a**
- **Alternation（选择）**：对于 $M \mid N$
- **Concatenation（连续，连接）**：$M \ast N$
- **Epsilon（空）**：$\epsilon$
- **Repetition（重复）**：重复一次，重复多次，至少重复一次

> Kleene closure: Given a regular expression M, its Kleene closure is $M^*$

使用以上这些基本规则，我们就可以来表示由 ASCII 字符组成的变成语言了。例如：

- $(0 \mid 1)^\ast \ast 0$ 表示任意能被 2 整除的二进制数

更多写法：

- $a$ : 普通字符
- $\epsilon$ : 空字符串
- $M \mid N$ : 选择 M 或 N
- $M \bullet N$ (MN) : 连接
- $M^\ast$ : 重复出现零次或多次
- $M^+$ : 重复出现一次或多次
- $M?$ : 出现一次或者不出现
- $[a-zA-Z]$: 再大小写字母中选择
- $\bullet$ : 表示任意字符
- "$a.+^\ast$" : 精确匹配完成字符串

在引入正则表达式后，我们就可以来描述词法规则了

假如有下面这样的 C 代码片段：
```c
if
{return IF;}

[a-z][a-z0-9]*
{return ID;}

[0-9]+
{return NUM; }

([0-9]+"."[0-9]*) | ([0-9]*"."[0-9]+)
{return REAL;}

("--"[a-z]*"\n")|(" "|"\n"|"\t")+
{/* do nothing */}

. {error();}
```

有关键字 **if**，标识符 **ID**，数字 **NUM**，以及实数 **REAL**，还定义了注释 『--』开头的单行注释。第五行是注释，意味着词法分析器会跳过它们继续执行，同时，词法分析器应该是功能完整的。它应该能够处理所有的符号，包括错误的。

写到这里，我们很快会注意到一个问题：**IF** 和 **ID** 这两个规则是有交集的。在没有假如更多规则的情况下，我们如何去识别 `if` 到底是 **ID token** 还是 **IF token**？再比如 `if8` 是先匹配 **IF** 规则还是先匹配 **ID** 规则？

下面引入两种常用的去歧义规则：

* **Longest match**：也就是最长匹配原则，规则所能匹配的最长子串作为下一个输出的 token。
* **Rule priority**：规则优先级原则，对于一个最长子串，第一个能够匹配的规则所表示 token 作为输。这也就意味着，匹配的顺序是有意义且重要的。

在引入了这两个规则之后，我们就可以确定 `if` 是 **IF** token 了，因为它最新匹配了 **IF**，同时 `if8` 是 **ID** token.

> 好了，到这里可以先简单的做一下总结。一门语言，有其最基本的语法元素，这里是 Lexical token。我们需要描述每一种 token 的规则，当然可以使用自然语言，但要让 Lexer 理解，必须要使用一种能实现成程序的方式。
> 于是我们引入了 Regular Expression 来描述词法规则。同时付加了两条消除歧义的规则，**最长匹配**和**匹配优先级**
> 那么，到这里我有一个疑问，**是不是使用 Regular Expression 就足够实现词法分析了？**

## FINITE AUTOMATA

前面有个问题：有了**正则表达式**，是不是就可以直接使用**正则**来实现词法匹配了？毕竟大多数的语言都有**正则**的实现。对的，用正则来实现词法分析器是完全没有问题的。

这里我正好在网上搜到了 Rob Pike 一篇文章 [Regular expression in lexing and parsing](https://commandcenter.blogspot.com/2011/08/regular-expressions-in-lexing-and.html)。摘取他的观点放在这里。

> Regular expressions are hard to write, hard to write well, and can be expensive relative to other technologies.

> A regular expression library is a big thing. Using one to parse identifiers is like using a Mack truck to go to the store for milk. And when we want to adjust our lexer to admit other character types, such as Unicode identifiers, and handle normalization, and so on, the hand-written loop can cope easily but the regexp approach will break down.

> Using regular expressions to explore the parse state to find the way forward is expensive, overkill, and error-prone.

>Regular expressions are, in my experience, widely misunderstood and abused.

这里我不深入这个问题，后面我会尝试实现一个基于**正则表达式**的词法分析器。

### 什么是有限自动机？

我们这里直接使用有限自动机来实现词法分析的功能。有限自动机由 **状态集**，**边**，**符号** 组成，状态有 **终结状态** 和 **开始状态**。有限自动机是一种状态机，它通过状态转化来实现接受或者拒绝特定字符串的功能。这里直接摘取维基百科对于状态机的定义。

> A finite-state machine (FSM) or finite-state automaton (FSA, plural: automata), finite automaton, or simply a state machine, is a mathematical model of computation. It is an abstract machine that can be in exactly one of a finite number of states at any given time. The FSM can change from one state to another in response to some external inputs; the change from one state to another is called a transition. An FSM is defined by a list of its states, its initial state, and the conditions for each transition. Finite state machines are of two types - deterministic finite state machines and non-deterministic finite state machines.

> The behavior of state machines can be observed in many devices in modern society that perform a predetermined sequence of actions depending on a sequence of events with which they are presented. Examples are vending machines, which dispense products when the proper combination of coins is deposited, elevators, whose sequence of stops is determined by the floors requested by riders, traffic lights, which change sequence when cars are waiting, and combination locks, which require the input of combination numbers in the proper order.

> The finite state machine has less computational power than some other models of computation such as the Turing machine.[2] The computational power distinction means there are computational tasks that a Turing machine can do but a FSM cannot. This is because a FSM's memory is limited by the number of states it has. FSMs are studied in the more general field of automata theory.

好了，现在引入了有限自动机这个概念。
有限自动机可以很方便的是现成程序。
有限自动机由：**状态集**，**边（从一个状态到另一个状态）**，**边上的符号**，**开始状态** 和 **终结状态** 组成。

有限自动机分为两种：

* DFA 确定性有限自动机：从一个状态接收，只有唯一确定的边指向另一个状态。
* NFA 非确定性有限自动机：从一个状态接收，有多个不同的状态可以到达。

由此，我们可以给上面的词法规则画出如下的几个状态机转化图：

![Fig 2.3]({{"/assets/images/state_machine_diagram_1.png"}})

我们也可以写成一个状态机转化图：

![Fig 2.4]({{"/assets/images/state_machine_diagram_2.png"}})

## EXERCISES

2.1 Write regular expressions for each of the following.

a. String over the alphabet $ \\{ a,b,c \\} $ where the first $a$ precedes the first $b$.

> 思路：因为必须第一个 $a$ 出现在第一个 $b$ 后面，所以实际上只有两种情况。
> 1. 第一个 $a$ 前面只有 $c$
> 2. 没有出现 $a$

> $ c^\ast a[abc]^\ast \mid [bc]^\ast $

b. String over the alphabet {a,b,c} with an even number of a's.

> 思路：需要 $a$ 的个数是偶数个
> 同样也分解情况。
> 1. 两个 $a$ 连续出现
> 2. 两个 $a$ 没有连续出现，中间有其他字符
> 3. 可以为空
> 将上面的三种情况组合起来，得到答案

> $ (a([bc]^\ast aa[bc]^\ast )^\ast a)^\ast $

c. Binary numbers that are multiples of four.
> $0\mid1^\ast00$

d. Binary numbers that are greater than 101001.
>

e. String over the alphabet {a,b,c} that don't contain the contiguous string baa.

f. The language of nonnegative integer constants in C, where numbers beginning with 0 are octal constants and other numbers are decimal constants.

g. Binary numbers n such that there exists an integer solution of $a^n + b^n = c^n$.
