with Interfaces;  use Interfaces;

package Block is

   type Uint_256 is array (1 .. 32) of Unsigned_8;

   type Block_Type is record
      Version : Unsigned_32;
      Prev_Block : Uint_256;
      Merkle_Root : Uint_256;
      Timestamp : Unsigned_32;
      Size : Unsigned_32;
      Nonce : Unsigned_32;
   end record;

   procedure Print_Block (B : Block_Type);

   function Uint_256_Hex (U : Uint_256) return String;

   function Block_Hash (B : Block_Type) return Uint_256;

   function Read_Block (File : String) return Block_Type;

end Block;
