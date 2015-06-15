stock float GetPlayerSpeed(int iClient)
{
    float faVelocity[3];
    GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", faVelocity);

    float fSpeed;
    fSpeed = SquareRoot(faVelocity[0] * faVelocity[0] + faVelocity[1] * faVelocity[1]);
    fSpeed *= GetEntPropFloat(iClient, Prop_Data, "m_flLaggedMovementValue");

    return fSpeed;
}
