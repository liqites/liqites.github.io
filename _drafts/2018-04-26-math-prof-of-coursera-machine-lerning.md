---
layout: post
title: Math Prof of Coursera Machine Learning
author: Tesla Lee
date: 2018-04-25 01:00:00 +0800
---
Keep updating...

<!---->
Here are some math proves that Andrew Ng didn’t show on the sildes of Machine Learning course from coursera.

Here are the function of Gradient Descent For Linear Regression of 2 parameters.

$\theta_0 := \theta_0 - \alpha\frac{1}{m}\sum_{i=1}^{m}((h_\theta(x^i) - y^i)x_0^i)$
$\theta_1 := \theta_1 - \alpha\frac{1}{m}\sum_{i=1}^{m}((h_\theta(x^i) - y^i)x_1^i)$

We know that the Gradient Descent algorithm is below:

$\theta_j := \theta_j - \alpha\frac{\delta}{\delta\theta_j}J(\theta)$

Actually I only care about the second part, the Partial Derivative.

Here we use the Cost Function: Mean squared error

$J(\theta) = \frac{1}{2m}\sum_{i=1}^{m}(h_\theta(x^i) - y_i)^2$

So, how to derive the result below?

$\frac{\delta}{\delta\theta_j}J(\theta) = \frac{1}{m}\sum_{i=1}^{m}((h_\theta(x^i) - y^i)x_j^i)$

Here is my prof, its easy, as I said, you just need to know the basic knowledge of derivatives.

$\frac{\delta}{\delta\theta_j}J(\theta) $

$= \frac{\delta}{\delta\theta_j} \frac{1}{2m}\sum_{i=1}^{m}(h_\theta(x^i) - y_i)^2$

$= \frac{\delta}{\delta\theta_j}\frac{1}{2m}\sum_{i=1}^{m}(h_\theta(x^i)^2 - 2h_\theta(x^i)y^i + (y^i)^2)$

$= \frac{1}{2m}\sum_{i=1}^{m}(\frac{\delta}{\delta\theta_j}h_\theta(x^i)^2 - \frac{\delta}{\delta\theta_j}2h_\theta(x^i)y^i +\frac{\delta}{\delta\theta_j} (y^i)^2)$

since:

$h_\theta(x) = \theta_0x_0^i + \theta_1x_1^i+...+\theta_nx_n^i$

we put it into the equation:

$=\frac{1}{2m}\sum_{i=1}^{m}(\frac{\delta}{\delta\theta_j}h_\theta(x^i)^2 - 2x_j^iy^i)$
