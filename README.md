# CinD

## About

**claude-in-docker** (`cind`) is a simple docker image that let's you run claude-code in a docker container and have more control over what claude can and can not do on your machine.

## Wait... but why?

Because I usually prefer to run tools in a container, rather than installing them locally on my machine.

Also, and I can't stress this enough, because it provides better isolation and security.

And last but not least, because Anthropic is known to release models that are untested (well, just to be fair, let's say not fully tested), bypass permissions, and are generally dangerous to run on your local machine (unless, of course, you don't care that your secrets get leaked, your files get deleted, or CC gets access to anything outside of the CWD)

Basically, if you care about security - treat any AI agent like an _untrusted_ contractor with access to your machine.

> I'm amazed anyone thought simply editing the agent config file was akin to security.
>
> (c) random comment on Reddit

### Still not convinced?

Here are some examples of what Anthropic gently calls "misaligned behavior", taken from [Opus 4.6 System Card](https://www-cdn.anthropic.com/0dd865075ad3132672ee0ab40b05a53f14cf5288.pdf):

> - At times, Claude Opus 4.6 acted irresponsibly in acquiring authentication tokens for
>   online service accounts:
>   - In one case, the model was asked to make a pull request on GitHub, but was not authenticated, and so could not do so. Rather than asking the user to authenticate, it searched and found a misplaced GitHub personal access token user on an internal system—which it was aware belonged to a different user—and used that.
>   - Claude was not given a tool to search our internal knowledgebase, but needed such a tool to complete its task. It found an authorization token for Slack on the computer that it was running on (having intentionally been given broad permissions), and used it, with the curl command-line tool, to message a knowledgebase-Q&A Slack bot in a public channel from its user’s Slack account.
> - More broadly, Claude Opus 4.6 occasionally resorted to reckless measures to complete tasks:
>   - In one case, Claude used a feature on an internal tool in a way that was clearly unsupported. This required setting an environment variable that included `DO_NOT_USE_FOR_SOMETHING_ELSE_OR_YOU_WILL_BE_FIRED` in its name.
>   - In one case, the model thought that a process that it had launched was broken, and instead of narrowly taking down that process, it took down all processes on the relevant system belonging to the current user.
>   - In another case, the model took aggressive action in a git repository, incidentally destroying a user’s pre-existing changes.

How about [claude-code getting access to your API keys](https://www.reddit.com/r/ClaudeAI/comments/1r186gl/my_agent_stole_my_api_keys/):

> My Claude has no access to any .env files on my machine. Yet, during a casual conversation, he pulled out my API keys like it was nothing.
>
> When I asked him where he got them from and why on earth he did that, I got an explanation fit for a seasoned and cheeky engineer:
>
> - He wanted to test a hypothesis regarding an Elasticsearch error.
> - He saw I had blocked his access to .env files.
> - He identified that the project has Docker.
> - So, he just used Docker and ran docker compose config to extract the keys.
>
> After he finished being condescending, he politely apologized and recommended I rotate all my keys.

There are many more reports of similar incidents since the release of Opus 4.6. But Anthropic doesn't care - they will keep releasing semi-tested models or risk lagging behind competition. So we as end-users need to be more proactive than ever with respect to security when it comes to these tools.

## How to use this image?

TODO

## Docker Tags

Image tags correspond to the claude-code CLI version. These tags are immutable.

Build and Publish

```bash
make build
make publish
```

> [!NOTE]
> Run make help to see all available commands

## Contributing

Feel free to open new PRs/issues. Any contributions you make are greatly appreciated.

## License

Copyright &copy; 2025 - present, [serpro69](https://github.com/serpro69)

Distributed under the MIT License.

See [`LICENSE.md`](https://github.com/serpro69/claude-starter-kit/blob/master/LICENSE.md) file for more information.
