with Types; use Types;

package Block is

   type Block_Type is record
      Version : Uint_32;
      Prev_Block : Uint_256;
      Merkle_Root : Uint_256;
      Timestamp : Uint_32;
      Bits : Uint_32;
      Nonce : Uint_32;
   end record;

   procedure Print_Block (B : Block_Type);

   function Block_Hash (B : Block_Type) return Uint_256;

   function Get_Block (Hash : String) return Block_Type;

end Block;
