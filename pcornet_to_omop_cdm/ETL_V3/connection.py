import snowflake.connector

ctx = snowflake.connector.connect(
user='mandhadiv@umsystem.edu',
account='xp02744.us-east-2.aws',
authenticator='externalbrowser'
)
cs = ctx.cursor()
try:
    cs.execute("SELECT current_version()")
    one = cs.fetchone()
    print(one[0])
finally:
    cs.close()




