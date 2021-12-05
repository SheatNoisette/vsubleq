module main

import os
import flag
import strconv

struct SubleqState {
mut:
	program         []int
	program_counter int
}


// Get a element from memory
[inline]
fn (mut sq SubleqState) get_memory(address int) int {
	return sq.program[address]
}

// Set a cell in memory
[inline]
fn (mut sq SubleqState) set_memory(address int, value int) {
	sq.program[address] = value
}

// Substract content pointed from addr1 and addr2 and set the memory at addr1
// Subleq
[inline]
fn (mut sq SubleqState) sub_memory(address_1 int, address_2 int) {
	sq.set_memory(address_1, sq.get_memory(address_1) - sq.get_memory(address_2))
}

[inline]
fn (mut sq SubleqState) next_instruction() {
	sq.program_counter = sq.program_counter + 3
}

fn (mut sq SubleqState) run_program() ? {
	for sq.program_counter >= 0 {
		a := sq.get_memory(sq.program_counter)
		b := sq.get_memory(sq.program_counter + 1)
		c := sq.get_memory(sq.program_counter + 2)

		if b == -1 {
			print('${byte(sq.get_memory(a)).ascii_str()}')
			sq.next_instruction()
			continue
		}

		sq.sub_memory(b, a)

		if sq.get_memory(b) < 1 {
			sq.program_counter = c
		} else {
			sq.next_instruction()
		}
	}
}

// Create a new Subleq struct
fn create_subleq(program_input []int) SubleqState {
	return SubleqState{
		program: program_input
		program_counter: 0
	}
}

// Parse a comma delimited string to a int list
fn parse_string(input string) ?[]int {
	mut out := []int{}

	for t in input.replace(' ', '').split(',') {
		content := strconv.atoi(t) or { return error('Unknown token $t') }
		out << content
	}

	return out
}

[noreturn]
fn print_error_and_exit(message string) {
	eprintln('vsubleq: $message')
	exit(1)
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Subleq interpreter')
	fp.version('0.0.1')
	fp.description('This program can run subleq programs')

	// Flags
	program_path := fp.string('file', `f`, '', 'Program path')
	program := fp.string('input', `i`, '', 'Program separated by commas')

	// Rest
	fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		exit(1)
	}

	mut program_string := ''

	if program.len > 0 {
		program_string = program
	} else if program_path.len > 0 {
		program_string = os.read_file(program_path) or {
			print_error_and_exit('Error while opening file: $err')
		}
	} else {
		print_error_and_exit('Input given, aborting...')
	}

	tokens := parse_string(program_string) or {
		print_error_and_exit('Error while parsing input: $err')
	}
	mut inter := create_subleq(tokens)

	// Run the program
	inter.run_program() or { print_error_and_exit('$err') }
}
