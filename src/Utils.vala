/*
 * Copyright (c) 2012 BeatBox Developers
 *
 * This is a free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

namespace Utils {

    /**
     * Description:
     * Receives a string and returns a valid search string.
     * This method can be used as a parser.
     *
     * Examples:
     *
     * INPUT:           OUTPUT:
     * "     Foo Bar "  "Foo Bar"     --> Removes trailing spaces from beginning and end
     * "             "  ""            --> Converts white space into a void string
     * "Foo   Bar"      "Foo    Bar"  --> Doesn't change middle spaces.
     */
    private string get_valid_search_string (string s) {

        if (s.length < 1)
            return "";

        bool found_valid_char = false;
        int white_space = 0, first_char_position = 0;
        unichar c;

        // WHITESPACE CHECK
        for (int i = 0; s.get_next_char (ref i, out c);) {
            if (c.isspace()) {
                ++ white_space;
            }
            else {
                found_valid_char = true;
                first_char_position = i; // position of the first valid character
                break; // no need to keep looping
            }
        }

        if (white_space == s.length)
            return "";

        if (found_valid_char) {
            var rv = new StringBuilder();

            int last_char_position = 0;
            for (int i = first_char_position - 1; s.get_next_char (ref i, out c);) {
                if (!c.isspace()) {
                    last_char_position = i;
                }
            }

            // Remove trailing spaces. In fact we just don't copy chars outside the
            // [first_valid_char, last_valid_char] interval.
            for (int i = first_char_position - 1; s.get_next_char (ref i, out c) && i <= last_char_position;) {
                    rv.append_unichar (c);
            }

            return rv.str;
        }

        return "";
    }
}

