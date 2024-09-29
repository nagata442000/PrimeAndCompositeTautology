module prime_and_composite #(
    parameter BIT_WIDTH = 4,   // Bit width of the natural number (e.g., 3-bit for numbers up to 7)
    parameter N = 4            // Number of primes/factors considered
)(
    input [BIT_WIDTH-1:0] target,        // Input natural number to be checked
    input [BIT_WIDTH-1:0] fact1,         // First factor of the target (for composite check)
    input [BIT_WIDTH-1:0] fact2,         // Second factor of the target (for composite check)
    input [BIT_WIDTH*N-1:0] all_primes,  // Array of known prime numbers
    input [BIT_WIDTH*N-1:0] generators,  // Array of generators for primes (used in primality test)
    input [BIT_WIDTH*N*N-1:0] pows,      // Powers array used in the primality test
    output reg result                    // Output result: 1 if target is both prime and composite, 0 otherwise
);

    integer i, j;                        // Loop counters
    reg [BIT_WIDTH-1:0] all_primes_array [0:N-1];   // Array for individual primes
    reg [BIT_WIDTH-1:0] generators_array [0:N-1];   // Array for individual generators
    reg [BIT_WIDTH-1:0] pows_array [0:N-1][0:N-1];  // 2D array for powers used in primality test
    reg [BIT_WIDTH*2-1:0] product, temp_power;      // Temporary variables for product and power calculations
    reg [BIT_WIDTH*2-1:0] mul_result;               // Temporary variable for multiplication result (composite check)
    reg [BIT_WIDTH*2-1:0] sum_pows;                 // Sum of powers for primality check
    reg condition1, condition2, condition3;         // Conditions for primality check
    reg condition_all_primes_array_are_prime;       // Final flag to check if all primes are valid
    reg condition_target_is_composite;              // Condition to check if the target is composite
    reg condition_target_is_prime;                  // Condition to check if the target is prime

    // Slice the input arrays into internal arrays
    always @* begin
        for (i = 0; i < N; i = i + 1) begin
            // Extract each prime from the input bit vector
            all_primes_array[i] = all_primes[i*BIT_WIDTH +: BIT_WIDTH];
            // Extract each generator from the input bit vector
            generators_array[i] = generators[i*BIT_WIDTH +: BIT_WIDTH];
            for (j = 0; j < N; j = j + 1) begin
                // Extract each power from the input bit vector
                pows_array[i][j] = pows[(i*N + j)*BIT_WIDTH +: BIT_WIDTH];
            end
        end
    end

    // Function to calculate base^exp % mod (modular exponentiation)
    function [BIT_WIDTH-1:0] power_mod;
        input [BIT_WIDTH-1:0] base, exp, mod;  // Base, exponent, and modulus
        reg [BIT_WIDTH*2-1:0] result;
        reg [BIT_WIDTH*2-1:0] x;
        integer k;
        begin
            result = 1;                 // Initialize result to 1
            x = base % mod;             // Reduce base mod
            for (k = 0; k < BIT_WIDTH; k = k + 1) begin
                if (exp[k] == 1) begin  // If exponent bit is 1, multiply result
                    result = (result * x) % mod;
                end
                x = (x * x) % mod;      // Square the base mod
            end
            power_mod = result;         // Return the result
        end
    endfunction

    // Function to calculate base^exp without modulo (used for internal powers)
    function [BIT_WIDTH*2-1:0] power;
        input [BIT_WIDTH-1:0] base, exp; // Base and exponent
        reg [BIT_WIDTH*2-1:0] result;
        reg [BIT_WIDTH*2-1:0] x;
        integer k;
        begin
            result = 1;                 // Initialize result to 1
            x = base;                   // Initialize base
            for (k = 0; k < BIT_WIDTH; k = k + 1) begin
                if (exp[k] == 1) begin  // If exponent bit is 1, multiply result
                    result = result * x;
                    if (result >= (1<<BITWIDTH)) begin // Check for overflow
                        result = 0;     // Reset result if overflow
                    end
                end
                x = x * x;              // Square the base
                if (x >= (1<<BIT_WIDTH)) begin // Check for overflow in base
                    x = 0;              // Reset base if overflow
                end
            end
            power = result;             // Return the result
        end
    endfunction

    always @* begin
        condition_all_primes_array_are_prime = 1;  // Initialize condition to true
        for (i = 0; i < N; i = i + 1) begin
            // Skip invalid primes (0 or 1)
            if (all_primes_array[i] == 0 || all_primes_array[i] == 1) begin
                condition_all_primes_array_are_prime = 0;
            end
            if (all_primes_array[i] != 2) begin
                // Calculate the product of all_primes[j]**pows[i][j]
                product = 1;
                for (j = 0; j < N; j = j + 1) begin
                    temp_power = power(all_primes_array[j], pows_array[i][j]);
                    if (temp_power >= (1<<BIT_WIDTH) || temp_power == 0) begin
                        condition_all_primes_array_are_prime = 0; // Overflow or zero means invalid
                    end
                    product = product * temp_power;
                    if (product >= (1<<BIT_WIDTH) || product == 0) begin
                        condition_all_primes_array_are_prime = 0; // Overflow or zero means invalid
                    end
                end
                sum_pows = 0;
                for (j = 0; j < N; j = j + 1) begin
                    sum_pows = sum_pows + pows_array[i][j]; // Sum powers
                end
                if (sum_pows <= 1) begin
                    condition_all_primes_array_are_prime = 0; // Sum of powers must be > 1
                end

                condition1 = (product + 1 == all_primes_array[i]); // Fermat's little theorem check
                
                // Check second condition using modular exponentiation
                condition2 = 1; // True by default
                for (j = 0; j < N; j = j + 1) begin
                    if (pows_array[i][j] != 0) begin
                        if (power_mod(generators_array[i], (all_primes_array[i] - 1) / all_primes_array[j], all_primes_array[i]) == 1) begin
                            condition2 = 0; // Fail if modular exponentiation returns 1
                        end
                    end
                end

                // Check third condition: generator^(prime-1) % prime == 1
                condition3 = (power_mod(generators_array[i], all_primes_array[i] - 1, all_primes_array[i]) == 1);

                if (!(condition1 && condition2 && condition3)) begin
                    condition_all_primes_array_are_prime = 0; // One of the conditions failed
                end
            end
        end

        // Check if the target number is composite
        condition_target_is_composite = 1;
        mul_result = fact1 * fact2; // Multiply the factors
        if (fact1 == target || fact2 == target) begin
            condition_target_is_composite = 0; // Target cannot be one of its factors
        end
        if (mul_result != target) begin
            condition_target_is_composite = 0; // Factors must multiply to target
        end

        // Check if the target number is prime
        condition_target_is_prime = 0;
        for (i = 0; i < N; i = i + 1) begin
            if (target == all_primes_array[i]) begin 
                condition_target_is_prime = 1; // Target is prime if it matches any known prime
            end
        end

        // The result is true if the target is both prime and composite (which is impossible, hence unsatisfiable CNF)
        result = condition_all_primes_array_are_prime && condition_target_is_composite && condition_target_is_prime;
    end
endmodule
