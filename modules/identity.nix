# Who I am. Identical on every machine, so it lives here rather than being
# repeated in each hosts/*/default.nix.
#
# None of this is secret: the name and both addresses are already in the author
# field of every commit in this repo, and a GPG key id is public by definition
# (it is what other people use to verify the signatures).
{
  my.identity = {
    fullName = "Alan Gabriel Sartorio";
    email = "alan42ga@hotmail.com";
    signingKey = "EAF6AB85F113D90BB428EF79EDDECA7EE635FD26";

    work = {
      dir = "~/Documents/CHYPS/";
      email = "asartorio@chyps.com.ar";
    };
  };
}
