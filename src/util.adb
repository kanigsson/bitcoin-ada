with GNATCOLL.Mmap;

package body Util is

   function Read_File_Into_Json (Fn : String) return JSON_Value is
      use GNATCOLL.Mmap;
      File   : Mapped_File;
      Region : Mapped_Region;

   begin
      File := Open_Read (Fn);

      Read (File, Region);

      declare
         S : String (1 .. Integer (Length (File)));
         for S'Address use Data (Region).all'Address;
         --  A fake string directly mapped onto the file contents

         J : constant JSON_Value := Read (S);
      begin
         Free (Region);
         Close (File);
         return J;
      end;

   end Read_File_Into_Json;

end Util;
