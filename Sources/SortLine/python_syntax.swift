/*

This file generates a abstractish syntax tree-ish for python using rough herustics. Noteably faults are:
	1) it does not trace across-files
	2) it does not recurse into packages
	3) it does not validate "right" and "wrong" python
	4) it does not support subclassing or inheritence

Parsing is done line so:
	1) class are detected using the class keyword
	2) The entire body of the class is decomposed into [Method]
	3) We loop over each method and aggregate full list of variables
	4) Using the signature of the __init__ method of the class
	(yes, classes without init are not supported) we infer the
	type of the variable. It does not support = None, then later
	= {} in a different method. The order of resolving the type
	of the variable is bottom up from the init function.
	5) A dictionary is created of variable -> methods
	6) Composite struct called class which is:
		variable_methods: [Variable-> [Method]]
		class_name: String
		class_content: String
	------------------------------------------------------------------
	That is the entire "parsing" pipeline then each lint rule works
	to it's own accord. For example the lr.p2 which prohibits collections
	that do not have mechanism to reset itself does coneptually a

	
	for (var, methods) in variable_methods
		variable_state_info ...
		for method in methods
			for lines in method.variable_op[var.name]
				analyse_line(line) -> update state

		if based on variable_state_info lint violation
		raise error.

	... This is psudo-code in reality this entire process is parallelised
	across classes throughout the entire codebase to achieve fast performance
	
*/

enum TypeOfVariable{
	case dict
	case list
	case string
	case number
	case object
	case unknown
}

struct Variable: Hashable, Equatable {
	let name: String
	let type: TypeOfVariable

	static func == (lhs: Variable, rhs: Variable) -> Bool{
		return lhs.name == rhs.name
	}
	
}

/// this struct represents a "method" these are bodies
/// of a class and contains some string and also
/// contains 'variables', now this struct does not
/// care to parse all variables within the body of
/// the fn rather only looks for access to variables
/// that effect the parents i.e. self.XXXXX, the same
/// thing for 'functions' as well these are fn's that
/// call into the class i.e. self.yyyy()
struct Method {
	let variables: [Variable] // the raw variable name excluding self.
	let variable_op: [Variable: [String]] // raw variable -> the full line
										// (as a string) on which the variable was used
	let functions: [String]
	let body: String
}

