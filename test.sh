fzf \
	--disabled \
	--prompt "Google❯ " \
	--bind 'change:reload:Q=$(echo {q} | sed "s/ /+/g"); curl -s "https://suggestqueries.google.com/complete/search?client=firefox&q=$Q" 2>/dev/null | python3 -c "import sys,json; [print(s) for s in json.load(sys.stdin)[1]]" 2>/dev/null || true' \
	--height=30% \
	--border=rounded \
	--color=prompt:cyan \
	--print-query \
	--preview "ddgr {}"
</dev/null
