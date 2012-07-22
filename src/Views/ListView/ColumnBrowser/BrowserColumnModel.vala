/*-
 * Copyright (c) 2011-2012      Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

using Gtk;
using Gee;

public class BeatBox.BrowserColumnModel : Object, TreeModel, TreeSortable {
	/* all iters must match this */
	private int stamp = (int)Random.next_int ();

	public int n_items { get { return rows.get_length () - 1; } } // Doesn't count the first ("All..") item

	/* data storage variables */
	private Sequence<string> rows;

	/* first iter. This helps us track the "All" row */
	TreeIter first_iter;

	/* treesortable stuff */
	private int sort_column_id;
	private SortType sort_direction;
	private unowned TreeIterCompareFunc default_sort_func;
	private HashMap<int, CompareFuncHolder> column_sorts;

	private BrowserColumn.Category category;

	/** Initialize data storage, columns, etc. **/
	public BrowserColumnModel (BrowserColumn.Category category) {
		rows = new Sequence<string> ();

		this.category = category;

		sort_column_id = -2;
		sort_direction = SortType.ASCENDING;
		column_sorts = new HashMap <int, CompareFuncHolder> ();
	}

	/** Returns a set of flags supported by this interface **/
	public TreeModelFlags get_flags () {
		return TreeModelFlags.LIST_ONLY;
	}

	/** Sets iter to a valid iterator pointing to path **/
	public bool get_iter (out TreeIter iter, TreePath path) {
		iter = TreeIter ();
		int path_index = path.get_indices ()[0];

		if (rows.get_length () == 0 || path_index < 0 || path_index >= rows.get_length ())
			return false;

		var seq_iter = rows.get_iter_at_pos (path_index);
		if (seq_iter == null)
			return false;

		iter.stamp = this.stamp;
		iter.user_data = seq_iter;

		return true;
	}

	/** Returns the number of columns supported by tree_model. **/
	public int get_n_columns () {
		return 1;
	}

	public Type get_column_type (int col) {
		return typeof (string);
	}

	/** Returns a newly-created Gtk.TreePath referenced by iter. **/
	public TreePath? get_path (TreeIter iter) {
		return new TreePath.from_string (((SequenceIter)iter.user_data).get_position ().to_string ());
	}

	/** Initializes and sets value to that at column. **/
	public void get_value (TreeIter iter, int column, out Value val) {
		val = Value (typeof (string));
		if (iter.stamp != this.stamp || column < 0 || column >= 1)
			return;

		if(!((SequenceIter<string>) iter.user_data).is_end ())
			val = rows.get (((SequenceIter<string>) iter.user_data));
	}

	/** Sets iter to point to the first child of parent. **/
	public bool iter_children (out TreeIter iter, TreeIter? parent) {
		iter = TreeIter ();

		return false;
	}

	/** Returns true if iter has children, false otherwise. **/
	public bool iter_has_child (TreeIter iter) {

		return false;
	}

	/** Returns the number of children that iter has. **/
	public int iter_n_children (TreeIter? iter) {
		if (iter == null)
			return rows.get_length ();

		return 0;
	}

	/** Sets iter to point to the node following it at the current level. **/
	public bool iter_next (ref TreeIter iter) {
		if (iter.stamp != this.stamp)
			return false;

		iter.user_data = ((SequenceIter)iter.user_data).next ();

		if (((SequenceIter)iter.user_data).is_end ())
			return false;

		return true;
	}

	/** Sets iter to be the child of parent, using the given index. **/
	public bool iter_nth_child (out TreeIter iter, TreeIter? parent, int n) {
		iter = TreeIter ();
		if (n < 0 || n >= rows.get_length() || parent != null)
			return false;

		iter.stamp = this.stamp;
		iter.user_data = rows.get_iter_at_pos (n);

		return true;
	}

	/** Sets iter to be the parent of child. **/
	public bool iter_parent (out TreeIter iter, TreeIter child) {
		iter = TreeIter ();

		return false;
	}

	/** Lets the tree ref the node. **/
	public void ref_node (TreeIter iter) {}

	/** Lets the tree unref the node. **/
	public void unref_node (TreeIter iter) {}

	/** simply adds iter to the model **/
	public void append (out TreeIter iter) {
		iter = TreeIter ();
		SequenceIter<string> added = rows.append ("");
		iter.stamp = this.stamp;
		iter.user_data = added;
	}

	/** convenience method to insert medias into the model. No iters returned. **/
	public void append_items (Collection<string> medias, bool emit) {
		add_first_element ();

		// We do some data validation for numeric values later
		bool is_rating = false, is_year = false;

		if (category == BrowserColumn.Category.RATING)
			is_rating = true;
		else if (category == BrowserColumn.Category.YEAR)
			is_year = true;


		foreach (string s in medias) {
			// if it is rating column, add "Stars" after the number
			if (is_rating) {
				int rating = int.parse (s);
				if (rating < 1)
					s = _("Unrated");
				else if (rating == 1)
					s = _("1 Star");
				else
					s = _("%s Stars").printf(s);
			}
			else if (is_year && int.parse(s) < 1) {
				// Don't add '0'
				continue;
			}

			SequenceIter<string> added = rows.append (s);

			if (emit) {
				var path = new TreePath.from_string (added.get_position().to_string());
				var iter = TreeIter ();

				iter.stamp = this.stamp;
				iter.user_data = added;

				row_inserted (path, iter);
			}
		}

		update_first_item ();
	}

	/* Add the "All" item */
	private void add_first_element () {
		SequenceIter<string> added = rows.append ("All");

		first_iter = TreeIter ();

		first_iter.stamp = this.stamp;
		first_iter.user_data = added;
	}

	/* Updates the "All" item */
	private void update_first_item () {
		rows.set ((SequenceIter<string>)first_iter.user_data, get_first_item_text (n_items));
	}


	// The text to use for the first item.
	private string get_first_item_text (int n_items) {
		string rv = "";

		// Exposing that %i could lead to many potential errors, but there's no other
		// way to allow correct grammar in other languages without doing it.
		switch (category) {
			case BrowserColumn.Category.GENRE:
				if (n_items == 1)
					rv = _("All Genres");
				else if (n_items > 1)
					rv = _("All %i Genres").printf (n_items);
				else
					rv = _("No Genres");
			break;
			case BrowserColumn.Category.ARTIST:
				if (n_items == 1)
					rv = _("All Artists");
				else if (n_items > 1)
					rv = _("All %i Artists").printf (n_items);
				else
					rv = _("No Artists");
			break;
			case BrowserColumn.Category.ALBUM:
				if (n_items == 1)
					rv = _("All Albums");
				else if (n_items > 1)
					rv = _("All %i Albums").printf (n_items);
				else
					rv = _("No Albums");
			break;
			case BrowserColumn.Category.YEAR:
				if (n_items == 1)
					rv = _("All Years");
				else if (n_items > 1)
					rv = _("All %i Years").printf (n_items);
				else
					rv = _("No Years");
			break;
			case BrowserColumn.Category.RATING:
				if (n_items >= 1)
					rv = _("All Ratings");
				else
					rv = _("No Ratings");
			break;
		}

		return rv;
	}


	public new void set (TreeIter iter, ...) {
		if (iter.stamp != this.stamp)
			return;

		var args = va_list (); // now call args.arg() to poll

		while (true) {
			int col = args.arg ();
			if (col < 0 || col >= 1)
				return;
			else if (col == 0) {
				string val = args.arg ();
				rows.set ((SequenceIter<string>)iter.user_data, val);
			}
		}
	}

	public void remove (TreeIter iter) {
		if (iter.stamp != this.stamp)
			return;

		var path = new TreePath.from_string (((SequenceIter)iter.user_data).get_position().to_string());
		rows.remove ((SequenceIter<string>)iter.user_data);
		row_deleted (path);
	}

	/** Fills in sort_column_id and order with the current sort column and the order. **/
	public bool get_sort_column_id (out int sort_column_id, out SortType order) {
		sort_column_id = this.sort_column_id;
		order = sort_direction;

		return true;
	}

	/** Returns true if the model has a default sort function. **/
	public bool has_default_sort_func () {
		return (default_sort_func != null);
	}

	/** Sets the default comparison function used when sorting to be sort_func. **/
	public void set_default_sort_func (owned TreeIterCompareFunc sort_func) {
		default_sort_func = sort_func;
	}

	/** Sets the current sort column to be sort_column_id. **/
	public void set_sort_column_id (int sort_column_id, SortType order) {
		bool changed = (this.sort_column_id != sort_column_id || order != sort_direction);

		this.sort_column_id = sort_column_id;
		sort_direction = order;

		if (changed && sort_column_id >= 0) {
			/* do the sort for reals */
			rows.sort_iter (sequenceIterCompareFunc);

			sort_column_changed ();
		}
	}

	/** Sets the comparison function used when sorting to be sort_func. **/
	public void set_sort_func (int sort_column_id, owned TreeIterCompareFunc sort_func) {
		column_sorts.set (sort_column_id, new CompareFuncHolder (sort_func));
	}


	/** Custom function to use built in sort in Sequence to our advantage **/
	public int sequenceIterCompareFunc (SequenceIter<string> a, SequenceIter<string> b) {
		int rv = 1;

		if (sort_column_id < 0)
			return 0;

		if (sort_column_id == 0) {
			var first_sequence_iter = (SequenceIter)first_iter.user_data;

			// "All" is always the first
			if (a == first_sequence_iter) {
				rv = -1;
			}
			else if (b == first_sequence_iter) {
				rv = 1;
			}
			else {
				rv = ((rows.get (a).down () > rows.get (b).down ()) ? 1 : -1);
			}
		}

		if(sort_direction == SortType.DESCENDING)
			rv = (rv > 0) ? -1 : 1;

		return rv;
	}
}
