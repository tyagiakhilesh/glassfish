#### Antlr2 usage

As of now, antlr2 maven plugin is used to generate the java source files and other relevant files and they are 
packaged as is in the target artifact where they are consumed by actual JQL related stuff.

#### Migration to antlr4

- Big problems: AST is no more!!! Should we write the whole query code again ?!
- Are there enough test cases around this functionality ?
- Huge difference between these 2 versions of antlr