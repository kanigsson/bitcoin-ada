with Interfaces;  use Interfaces;

package Block is

   type Uint_256 is array (1 .. 32) of Unsigned_8;

   type Block is record
      Version : Unsigned_32;
      Prev_Block : Uint_256;
      Merkle_Root : Uint_256;
      Timestamp : Unsigned_32;
      Size : Unsigned_32;
      Nonce : Unsigned_32;
   end record;


   procedure Read_Blocks (File : String);

end Block;
