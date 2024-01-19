{
  description = "Nix templates";
  outputs = { self }: {
    templates = {
      haskell = {
        path = ./haskell;
        description = "haskell";
      };
    };
  };
}
