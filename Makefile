pushGit:
	git add .
	git commit -m "commit de $(shell date +%Y-%m-%d)"
	git push
