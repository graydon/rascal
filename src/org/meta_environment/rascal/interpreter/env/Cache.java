package org.meta_environment.rascal.interpreter.env;

import java.util.HashMap;
import java.util.Map;

import org.eclipse.imp.pdb.facts.IValue;
import org.meta_environment.rascal.interpreter.asserts.ImplementationError;
import org.meta_environment.rascal.interpreter.result.CalleeCandidatesResult;
import org.meta_environment.rascal.interpreter.result.Result;


public class Cache {
	// TODO: fix dependency on internals of Environment (e.g. Map<String,...> etc.).
	
	private final HashMap<VariableCacheEntry,Result<IValue>> variables;
	private final Map<FunctionCacheEntry, CalleeCandidatesResult> functions;
//	private final Map<CacheEntry<Map<String,List<Lambda>>>, List<Lambda>> functions2;
	private boolean enabled;
	
	
	public Cache() {
		variables = new HashMap<VariableCacheEntry, Result<IValue>>();
		functions = new HashMap<FunctionCacheEntry, CalleeCandidatesResult>();
		enabled = true;
	}
	
	public void save(Map<String, CalleeCandidatesResult> env, String name, CalleeCandidatesResult other) {
		CalleeCandidatesResult list = null;
		if (other != null) {
			list = new CalleeCandidatesResult(name).join(other);
		}
		functions.put(new FunctionCacheEntry(env, name), list);
	}
	
	public void save(Map<String, Result<IValue>> env, String name, Result<IValue> result) {
		variables.put(new VariableCacheEntry(env, name), result);
	}
	
	public boolean containsVariable(Map<String, Result<IValue>> env, String name) {
		return variables.containsKey(new VariableCacheEntry(env, name));
	}
	
	public boolean containsFunction(Map<String, CalleeCandidatesResult> env, String name) {
		return functions.containsKey(new FunctionCacheEntry(env, name));
	}
	
	public void commit() {
		if (!isEnabled()) {
			throw new ImplementationError("trying to commit cache when it's not enabled");
		}
		enabled = false;
	}
	
	public boolean isEnabled() {
		return enabled;
	}
	
	public void rollback() {
		if (!isEnabled()) {
			throw new ImplementationError("trying to restore cache which is not enabled.");
		}
		enabled = false;
		for (Map.Entry<VariableCacheEntry, Result<IValue>> entry: variables.entrySet()) {
			Map<String, Result<IValue>> env = entry.getKey().env;
			String name = entry.getKey().name;
			Result<IValue> value = entry.getValue();
			// NULL indicates the variable was unbound before.
			if (value == null) {
				env.remove(name);
			}
			else {
				env.put(name, entry.getValue());
			}
		}
		for (Map.Entry<FunctionCacheEntry, CalleeCandidatesResult> entry: functions.entrySet()) {
			Map<String, CalleeCandidatesResult> env = entry.getKey().env;
			String name = entry.getKey().name;
			CalleeCandidatesResult value = entry.getValue();
			// NULL indicates name had no function bindings.
			if (value == null) {
				env.remove(name);
			}
			else {
				env.put(name, value);	
			}
		}
	}
	
	private class FunctionCacheEntry {
		private Map<String,CalleeCandidatesResult> env;
		private String name;

		public FunctionCacheEntry(Map<String, CalleeCandidatesResult> env, String name) {
			this.env = env;
			this.name = name;
		}
		
		@Override
		public boolean equals(Object o) {
			if (!(o instanceof FunctionCacheEntry)) {
				return false;
			}
			FunctionCacheEntry entry = (FunctionCacheEntry)o;
			return env == entry.env && name.equals(entry.name);
		}
	}

	private class VariableCacheEntry {
		private Map<String, Result<IValue>> env;
		private String name;

		public VariableCacheEntry(Map<String, Result<IValue>> env, String name) {
			this.env = env;
			this.name = name;
		}
		
		@Override
		public boolean equals(Object o) {
			if (!(o instanceof VariableCacheEntry)) {
				return false;
			}
			VariableCacheEntry entry = (VariableCacheEntry)o;
			return env == entry.env && name.equals(entry.name);
		}
	}

}
