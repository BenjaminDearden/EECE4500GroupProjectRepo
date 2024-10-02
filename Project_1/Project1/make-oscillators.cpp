#include <iostream>
#include <random>
#include <tuple>
#include <fstream>
#include <string>

auto main() -> int {
	constexpr size_t total_inverters = 12;
	constexpr size_t total_oscillators = 8;
	std::random_device rd{};
	std::mt19937 rng{ rd() };
	std::normal_distribution distribution{ 1.0, 0.05 };

	auto in_range = [](auto x, auto mu, auto k)
		{ return (mu - k) <= x && x <= (mu + k); };
	auto get_random = [&distribution, &rng, in_range](auto range) {
		double t;
		do {
			t = distribution(rng);
		} while (!in_range(t, 1, range));
		return t;
		};

	auto get_size_variations = [get_random]() {
		return std::make_tuple(get_random(0.15), get_random(0.15),
			get_random(0.15), get_random(0.15));
		};

	auto get_thickness_variations = [get_random]() {
		return std::make_tuple(get_random(0.10), get_random(0.10));
		};

	for(size_t j = 0; j < total_oscillators; j++){
		std::ofstream file("ring_oscillator" + std::to_string(j) + ".sp");
		if (!file.is_open()) {
			std::cerr << "Could not open file" << std::endl;
			return 1;
		}
		//file << "write spice file" << std::endl;
		// TODO: add proper SPICE header and start for the subcircuit card
		file << "*.subckt ring_oscillator enable osc_out" << std::endl << std::endl;


		// TODO: add the NAND gate

		file << "x0 enable out12 nand" << std::endl << std::endl;


	// generate inverters
		for (size_t i = 0; i < total_inverters; i++) {
			// change to match your inverter parameters
			auto [tplv, tpwv, tnln, tnwn] = get_size_variations();
			auto [tpotv, tnotv] = get_thickness_variations();
			file
				<< "x" << (i + 1) << " in" << i << " out" << (i + 1) << " inverter"
				<< " tplv=" << tplv << " tpwv=" << tpwv
				<< " tnln=" << tnln << " tnwn=" << tnwn
				<< " tpotv=" << tpotv << " tnotv=" << tnotv
				<< std::endl;
		}

		// TODO: add the end of the subcircuit card
		file << std::endl << ".ends" << std::endl;
		file.close();
	}
	
}
