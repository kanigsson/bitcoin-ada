with Types; use Types;

package Block is

   type Block_Header is record
      Version : Uint_32;
      Prev_Block : Uint_256;
      Merkle_Root : Uint_256;
      Timestamp : Uint_32;
      Bits : Uint_32;
      Nonce : Uint_32;
   end record;

   type Transaction_Array is array (Integer range <>) of Uint_256;

   type Block_Type (Num_Transactions : Integer) is record
      Header : Block_Header;
      Transactions : Transaction_Array (1 .. Num_Transactions);
   end record;

   procedure Print_Block (B : Block_Type);

   function Block_Hash (B : Block_Type) return Uint_256;

   function Get_Block (Hash : String) return Block_Type;
   --  get a block based on its hash; this uses bitcoin-cli, so assumes that
   --  there is a bitcoind running on this machine

   procedure Check_Block (B : Block_Type);
   --  check the validity of the block; stop the program if the block is
   --  invalid

end Block;
