 * Have cascading data format.  If you fail to find data in YAML files
   then look in in-puppet data using an approach similar to Nigels for
   example.  This way module authors can provide default data in modules
   and module users can provide data in YAML/JSON etc.  - Cody Herriges
 * Make the data dir parameterized so you can have different directories
   full of data based on environment for example.  - Aaron Grewell
 * Move the Util* stuff into a Gem so as a standalone queryable hierarchial
   data source, this kind of data and kind of store has value outside of
   CM.  But also just so you can query the data from elsewhere like the
   https://github.com/jordansissel/extlookup.rb example shows - Jordan Sissel
