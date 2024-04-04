{ config, lib, pkgs, ... }:

{
  users.users.gavin = {
    isNormalUser = true;
    description = "gavin";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ ];
    openssh = {
      authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCepT1fLVknsLMpimGx4IFuhHLV7kZc6w1tqfU0yRUqGTvVZLjoZa68zh1mlg4bsMSkJbQCkk0/F0ZF6wmkYItgNUIK/UY7yfNc8Y4yjfGQw5hW5p65dqB0qSwrB7y+UM2I5y2Xt1EOST9ZpYMzWpCaX3xeJ3dBVGzE4mMlJ1hPaCOqw2pzc0DAWonhf7CV3VxbHuvb/MBTYn/dpmF7h87RPuSTym/68H4irM0EAZerK/Wlxx0/uAH53EoNAr43/EAI6NskKr2SHNLNjOjm/AzDxtTLgEs/Xp3TVWjHp94KC1VabV5CqX9FE1pgStGaTpJ4XD127KaxgDlEpdXyjXxDLGjNdV+6qm9rx25voklDylAXenK/8aW4B8R4lyrpzgoIiCKq7LKf1blZUyV3t3gUpsSd4r1WfIBSJYz0yWlzQPHj3b9dfRVduGT1+7gHH3wlLueQi1CM5+iMXWVyE46MYefoNHbMh4vF/aLL/hoJ3rLhCm93euDsv22xDe+Tj1ZL1g6xciVfq1sIItOyVrv3vD/KZldl9ltYr58v5Dp5HiYvkCwwUdeeno8dyBtiXWcTieBoifWYxx3vc8pb4Cb/elvD4YnkXyVCUHb2zEkA5St3EeVoPr66ectery8OfwzPgR/zJdvLDVCQGh1EOgXBXnOV2vfNy9om+4qdATCG2Q== ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCepT1fLVknsLMpimGx4IFuhHLV7kZc6w1tqfU0yRUqGTvVZLjoZa68zh1mlg4bsMSkJbQCkk0/F0ZF6wmkYItgNUIK/UY7yfNc8Y4yjfGQw5hW5p65dqB0qSwrB7y+UM2I5y2Xt1EOST9ZpYMzWpCaX3xeJ3dBVGzE4mMlJ1hPaCOqw2pzc0DAWonhf7CV3VxbHuvb/MBTYn/dpmF7h87RPuSTym/68H4irM0EAZerK/Wlxx0/uAH53EoNAr43/EAI6NskKr2SHNLNjOjm/AzDxtTLgEs/Xp3TVWjHp94KC1VabV5CqX9FE1pgStGaTpJ4XD127KaxgDlEpdXyjXxDLGjNdV+6qm9rx25voklDylAXenK/8aW4B8R4lyrpzgoIiCKq7LKf1blZUyV3t3gUpsSd4r1WfIBSJYz0yWlzQPHj3b9dfRVduGT1+7gHH3wlLueQi1CM5+iMXWVyE46MYefoNHbMh4vF/aLL/hoJ3rLhCm93euDsv22xDe+Tj1ZL1g6xciVfq1sIItOyVrv3vD/KZldl9ltYr58v5Dp5HiYvkCwwUdeeno8dyBtiXWcTieBoifWYxx3vc8pb4Cb/elvD4YnkXyVCUHb2zEkA5St3EeVoPr66ectery8OfwzPgR/zJdvLDVCQGh1EOgXBXnOV2vfNy9om+4qdATCG2Q== openpgp:0xE17CD02D"
      ];
    }
  };
}
