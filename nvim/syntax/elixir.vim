autocmd User ProjectionistDetect
\ call projectionist#append(getcwd(),
\ {
\    'web/*.ex':  {
\       'alternate': 'test/{}_test.exs'
\    },
\    'web/models/*.ex':  {
\       'alternate': 'test/{}_test.exs'
\    },
\    'lib/*.ex': {
\       'alternate': 'test/{}_test.exs',
\       'skeleton': 'defm'
\    },
\    'test/*_test.exs':  {
\      'alternate': 'web/{}.ex',
\     },
\ })
