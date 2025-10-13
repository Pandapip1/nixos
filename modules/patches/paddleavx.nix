{
  nixpkgs.overlays = [
    (_: prev: {
      python312Packages = prev.python312Packages // {
        safetensors = prev.python312Packages.safetensors.overridePythonAttrs {
          optional-dependencies = lib.fix (self: {
            numpy = [ numpy ];
            torch = self.numpy ++ [
              torch
            ];
            tensorflow = self.numpy ++ [
              tensorflow
            ];
            pinned-tf = self.numpy ++ [
              tensorflow
            ];
            jax = self.numpy ++ [
              flax
              jax
            ];
            mlx = [
              mlx
            ];
            testing = self.numpy ++ [
              h5py
              huggingface-hub
              setuptools-rust
              pytest
              pytest-benchmark
              hypothesis
              fsspec
            ];
            all = self.torch ++ self.numpy ++ self.pinned-tf ++ self.jax ++ self.paddlepaddle ++ self.testing;
            dev = self.all;
          });
        };
      };
      python313Packages = prev.python313Packages // {
        safetensors = prev.python313Packages.safetensors.overridePythonAttrs {
          optional-dependencies = lib.fix (self: {
            numpy = [ numpy ];
            torch = self.numpy ++ [
              torch
            ];
            tensorflow = self.numpy ++ [
              tensorflow
            ];
            pinned-tf = self.numpy ++ [
              tensorflow
            ];
            jax = self.numpy ++ [
              flax
              jax
            ];
            mlx = [
              mlx
            ];
            testing = self.numpy ++ [
              h5py
              huggingface-hub
              setuptools-rust
              pytest
              pytest-benchmark
              hypothesis
              fsspec
            ];
            all = self.torch ++ self.numpy ++ self.pinned-tf ++ self.jax ++ self.paddlepaddle ++ self.testing;
            dev = self.all;
          });
        };
      };
    })
  ];
}
