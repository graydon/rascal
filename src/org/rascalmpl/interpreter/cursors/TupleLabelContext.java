package org.rascalmpl.interpreter.cursors;

import org.rascalmpl.library.util.Cursor;
import io.usethesource.vallang.IList;
import io.usethesource.vallang.ITuple;
import io.usethesource.vallang.IValue;
import io.usethesource.vallang.IValueFactory;

public class TupleLabelContext extends Context {

	private final Context ctx;
	private final String label;
	private final ITuple tuple;

	public TupleLabelContext(Context ctx, String label, ITuple tuple) {
		this.ctx = ctx;
		this.label = label;
		this.tuple = tuple;
	}

	@Override
	public IValue up(IValue focus) {
		return new TupleCursor(tuple.set(label, focus), ctx);
	}

	@Override
	public IList toPath(IValueFactory vf) {
		return ctx.toPath(vf).append(vf.constructor(Cursor.Nav_fieldPosition, vf.integer(tuple.getType().getFieldIndex(label))));
	}
}
