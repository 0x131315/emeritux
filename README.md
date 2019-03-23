# emeritux.sh

A Bash script to build Enlightenment 23 GIT on Linux Mint 19.1 Tessa  
(support for 32-bit and 64-bit architectures).

While this script has been thoroughly tried and tested, it's a good idea to use Timeshift  
to create a system snapshot before the first run, as an extra safety precaution.

## **Get started**

Make sure that the `git` package is installed, then open Terminal and clone this repository:

```bash
git clone https://github.com/batden/emeritux.git
```

That creates a new folder named  _"emeritux"_  in your home directory.

Please copy the file  _"emeritux.sh"_  from this new folder to the download folder.

Now change to the download folder and make the script executable:

```bash
chmod +x emeritux.sh
```

Then issue the following command:

```bash
./emeritux.sh
```

On subsequent runs, open Terminal and simply type:

```bash
emeritux.sh
```

(Use tab completion: Just type  _eff_  and press Tab)

### **Update local repository**

Be sure to check for updates at least once a week.

In order to do this, change to ~/emeritux/ and run:

```bash
git pull
```
