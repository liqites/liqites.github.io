---
layout: post
title:  "Ruby Refinements Documented"
author: Tesla Lee
date:   2017-11-22 22:53:12 +0800
categories: ruby
---
本文主要记录了 Refinement 使用的一些要点，内容基本来自 Ruby 的官方文档以及 Metaprogramming Ruby 这本书。

<!--more-->

有时，我们往往会遇到一些情况，需要对系统的类做重新打开的操作，同时再添加一些自己的扩展。Ruby 提供了多种不同的方法来实现，其中之一就是打开类。

```ruby
class String
  def a_new_method
  end
end
```

但这样的写法有一个问题，这样的修改是全局的，一旦定义，整个系统都会受影响。如果出错，将会是灾难性的。
那么，有没有什么方法，能够将这个修改只在我需要使用的范围内起作用呢？ Ruby 提供了 Refinement 来帮助你实现。

先看一段 Ruby 官方文档。来自 Ruby 2.2.4
> Refinements are designed to reduce the impact of monkey patching on other users of the monkey-patched class.Refinements provide a way to extend a class locally.

下面下看一个典型的 Refinement 的例子：

```ruby
class C
  def foo
    puts "C#foo"
  end
end

module M
  refine C do
    def foo
      puts "C# foo in M"
    end
  end
end
```

要点：
* `Module#refine` 只能接收 class 作为参数
* `Module#refine` 会创建一个匿名 module 并且修改包裹在内。在 `refine` block 中，`self` 指向这个匿名 module

### 作用域

> You may only activate refinements at top-level, not inside any class, module or method scope. You may activate refinements in a string passed to Kernel#eval that is evaluated at top-level. Refinements are active until the end of the file or the end of the eval string, respectively.

下面用官方的两个例子来说明 Refinement 的作用域问题

```ruby
class C
end

module M
  refine C do
    def foo
      puts "C#foo in M"
    end
  end
end

def call_foo(x)
  x.foo
end

using M

x = C.new
x.foo       # prints "C#foo in M"
call_foo(x) #=> raises NoMethodError
```

在这里，当调用 `call_foo` 时，控制权从当前作用域（假设叫做 Scope A）进入到了 `call_foo` 这个 `method` 的作用域（Scope B）中去了。
所以，根据规则
* **当控制权发生改变，跳出了当前 Refinement 生效的作用域时，Refinement 失效。**

接下来第二个例子：

c.rb:

```ruby
class C
end
```

m.rb

```ruby
require "c"

module M
  refine C do
    def foo
      puts "C#foo in M"
    end
  end
end
```

m_user.rb

```ruby
require "m"

using M

class MUser
  def call_foo(x)
    x.foo
  end
end
```

main.rb

```ruby
require "m_user"

x = C.new
m_user = MUser.new
m_user.call_foo(x) # prints "C#foo in M"
x.foo              #=> raises NoMethodError
```

我们可以认为，Refinement 生效的作用域只在 m_user.rb 这个文件内。当我们调用 `m_user.call_foo(x)` 时，我们进入了 m_user.rb 这个文件的作用域，也就是 Refinement 生效了。而结束后调用后，又回到了 main.rb 这个文件的作用域内，此时 Refinement 已经失效，所以爆了 `NoMethodError` 这个 Exception。

* **在定义 Refinement 时，在同一个 module 中的所有 refinements 都是相互生效的。**

下面这一条有点奇怪。
> You may also activate refinements in a class or module definition, in which case the refinements are activated from the point where using is called to the end of the class or module definition:

我觉得这段话和上面的那段话
> You may only activate refinements at top-level, not inside any class, module or method scope. You may activate refinements in a string passed to Kernel#eval that is evaluated at top-level. Refinements are active until the end of the file or the end of the eval string, respectively.

**有点矛盾，我现在的疑问是，是不是我对于 TOP LEVEL 这个概念理解有偏差。**

但是对于这个定义，我没有异议。看下面。

```ruby
# not activated here
class Foo
  # not activated here
  using M
  # activated here
  def foo
    # activated here
  end
  # activated here
end
# not activated here
```

**有一点要注意：M 只在这次的 Scope 中生效，后面再打开 Foo 中，M 也不会生效。**

### 方法查找

当在一个类 C 的实体上查找方法时，顺序是这样的
* 如果有多个 Refinement 生效，那么将按照每个 refinement 生效的顺序，反向查找 refinement 内部的方法。
  * refinement 中 prepend 的 module 中的 method
  * refinement 中的 method
  * refinement 中 include 的 module 中的 method
* prepend 的 module 中的 method
* C 中的 method
* include 的 module 中的 method
如果没有，则继续查找 superclass，重复上面的顺序

比如下面的代码

```ruby
class A

end

module M1
  def foo
    puts "A foo in M1"
  end
end

module M2
  def foo
    puts "A foo in M2"
  end
end

module M3
  def foo
    puts "A foo in M3"
  end
end

module M4
  def foo
    puts "A foo in M4"
  end
end

module M5
  def foo
    puts "A foo in M5"
  end
end

module AExtend 
  refine A do
    include M1
    prepend M2

    def foo
      puts "A foo in AExtend"
    end
  end
end

class A
  using AExtend
  include M3
  prepend M4
end

puts using AExtend
puts A.new.foo # A foo in M2
puts A.ancestors # [M4, A, M3, Objcet, Kernel, BasicObject]
```

对于第一个输出，其实没有异议。那么为什么此时打印 `A.ancestors` 时，却没有 `M1` 和 `M2` 呢？
我倾向于认为，因为进入到了 `ancestors` 这个函数里，所以控制权已经发生了改变， AExtend 已经失效了。

### super 
`super` 的方法查找
* 查找所有 included modules 
* 如果当前是 refinement class，重复上面步骤
* 如果当前 class 有 superclass，则在 superclass 上重复上面步骤

### 非直接调用
目前 refinement 对于 Kernel#send，Kernel#method 以及 Kernel#respond_to? 都不起作用

### 在 include 中的方法查找【此处已经被移除】
看下面的示例

```ruby
class A

end

module AExtend1
  refine A do
    def foo
      puts "A foo in AExtend1"
    end
  end
end

module AExtend2
  refine A do
    def foo
      puts "A foo in AExtend2"
    end
  end
end

module AExtend3
  include AExtend2
  include AExtend1

  # refine A do
  #   def foo
  #     puts "A foo in AExtend3"
  #   end
  # end
end

class A
end

using AExtend3
puts A.new.foo # A foo in AExtend1
```

方法查找的顺序是
* 先查找 AExtend3 中的 refinement
* 再按照 prepend 以及 include 的顺序来查找，也就是 ancestors 继承链中的顺序从前往后查找。

### 总结
第一次了解 Refinement，感觉还有一点乱，虽然可以用来避免 Monkey Patch 的全局影响问题，但是要想使用好，还需要花时间。
