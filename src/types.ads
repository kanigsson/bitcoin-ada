with Interfaces;  use Interfaces;

package Types is

   type Uint_8 is new Unsigned_8;
   type Uint_32 is new Unsigned_32;
   type Uint_256 is array (1 .. 32) of Uint_8;

   Uint_256_0 : constant Uint_256 := (others => 0);


end Types;
