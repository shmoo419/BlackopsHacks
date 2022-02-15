# BlackopsHacks
### @hackedbyshmoo

**Point Modifier, Wave Modifier, Always Spawn Pickups**

A (non-Unity) example of abusing static classes and applying hacks via threading.

In IDA Pro, if you search for the string `SystemStatic`, you'll get a list of all the static classes in the game. Too bad there's so few of them.
To get the constant pointer to a static class, search for the class name. For example, `CScoreManager`.
Go down the list of xrefs until you find yourself in what seems to be a constructor.
The first instruction that starts with `STR X19` has the constant pointer you need.
In this case, the instruction is `STR X19, [X0,#0x100638240@PAGEOFF]`, so our constant pointer to `CScoreManager` is at `0x100638240`.

Keep in mind this was done with a ton of memory inspection. None of this is magic, it just takes a lot of poking around in memory to find what you need. This didn't take me an hour to make, more like three.

By the way, IDA doesn't explore most of the binary for some reason. You'll have to convert code to code and strings to strings yourself.

Tutorial: https://iosgods.com/topic/70716-static-members-and-multithreading/
