# Identity

Let’s get one thing straight: Authentication has _nothing_ to do with your personal identity.

The definition of authentication reads

> the process or action of proving or showing something to be true, genuine, or valid.

However, within the context of computing, the definition reads:

> the process or action of verifying the identity of a user or process.

This definition includes the concept of identity.

There is no problems with this definition. The problem arises when we start implementing authentication.

We mixed the concept of identity within the context of computing with the concept of identity within the context of humans.

Those are two very different concepts.

One talks about your personal identity. Your name, eye color, address, religious views, political views. All that stuff. 

The other is just a number or string that identifies **something**. And what that something is, is totally unrelated to the identify itself.

Promise wants to provide authentication completely decoupled from personal identity. We will go out of our way to make sure that relying parties will receive no information from us that in any way can relate to your personal identity.

Also, we will make sure that no personal data will be stored on our servers. No employee of Promise or no hacker will ever be able to use data stored on our servers to personally identify you. Ever. 

